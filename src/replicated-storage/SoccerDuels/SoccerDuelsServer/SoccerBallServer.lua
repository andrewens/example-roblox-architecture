-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local CharacterServer = require(SoccerDuelsServerModule.CharacterServer)
local MapsServer = require(SoccerDuelsServerModule.MapsServer)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local BALL_WELD_OFFSET = Config.getConstant("SoccerBallWeldOffsetLocalCoordinates")
local SECONDS_AFTER_GOAL_BALL_IS_DESTROYED = Config.getConstant("SecondsAfterGoalBallIsDestroyed")
local MAX_SOCCER_BALL_KICK_SPEED = Config.getConstant("MaxSoccerBallKickSpeed")
local MIN_SOCCER_BALL_KICK_SPEED = Config.getConstant("MinSoccerBallKickSpeed")
local MAX_DISTANCE_TO_POSSESS = Config.getConstant("MaxDistanceStudsBetweenBallAndPlayerToPossess")

-- var
local numSoccerBallsCreated = 0
local SoccerBallIdToPart = {} -- int soccerBallId --> BasePart
local SoccerBallIdToMapId = {} -- int soccerBallId --> int mapId
local SoccerBallIdToPossessingPlayer = {} -- int soccerBallId --> Player | nil
local SoccerBallIdToPreviousPossessingPlayer = {} -- int soccerBallId --> Player | nil
local PossessingPlayerToBallId = {} -- Player --> int soccerBallId
local SoccerBallIdToGoalDestroyTimestamp = {} -- int soccerBallId --> int unixTimestampMilliseconds (these are balls in a goal)

local SoccerBallsFolder

-- private
local destroySoccerBall
local function removePlayerSoccerBallOwnership(PossessingPlayer, soccerBallId)
	PossessingPlayerToBallId[PossessingPlayer] = nil
	SoccerBallIdToPossessingPlayer[soccerBallId] = nil

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	local Weld = SoccerBallPart:FindFirstChildWhichIsA("WeldConstraint")
	if Weld then
		Weld:Destroy()
	end
end
local function givePlayerSoccerBallOwnership(PossessingPlayer, soccerBallId)
	local playerCFrame = Utility.getPlayerCharacterCFrame(PossessingPlayer)
	if playerCFrame == nil then
		return
	end

	local HumanoidRootPart = PossessingPlayer.Character.HumanoidRootPart
	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]

	PossessingPlayerToBallId[PossessingPlayer] = soccerBallId
	SoccerBallIdToPossessingPlayer[soccerBallId] = PossessingPlayer
	SoccerBallIdToPreviousPossessingPlayer[soccerBallId] = PossessingPlayer

	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = HumanoidRootPart
	Weld.Part1 = SoccerBallPart
	Weld.Parent = SoccerBallPart

	SoccerBallPart.Position = playerCFrame.Position
		+ playerCFrame.RightVector * BALL_WELD_OFFSET.X
		+ playerCFrame.UpVector * BALL_WELD_OFFSET.Y
		+ playerCFrame.LookVector * BALL_WELD_OFFSET.Z
end

local function getClosestUnpossessedBallIdToPosition(position)
	local closestDistanceSquared = math.huge
	local closestBallId

	for soccerBallId, SoccerBallPart in SoccerBallIdToPart do
		if SoccerBallIdToPossessingPlayer[soccerBallId] then
			continue
		end

		if SoccerBallIdToGoalDestroyTimestamp[soccerBallId] then
			continue
		end

		local offset = SoccerBallPart.Position - position
		local distanceSquared = offset:Dot(offset)

		if distanceSquared < closestDistanceSquared then
			closestBallId = soccerBallId
			closestDistanceSquared = distanceSquared
		end
	end

	return closestBallId, closestDistanceSquared
end
local function getClosestUnpossessingPlayerToPosition(mapId, position)
	local ClosestPlayer
	local closestDistanceSquared = math.huge

	for Player, teamIndex in MapsServer.getPlayersConnectedToMapInstance(mapId) do
		if PossessingPlayerToBallId[Player] then
			continue
		end

		local characterPosition = Utility.getPlayerCharacterPosition(Player)
		if characterPosition == nil then
			continue
		end

		local offset = position - characterPosition
		local distanceSquared = offset:Dot(offset)

		if distanceSquared < closestDistanceSquared then
			ClosestPlayer = Player
			closestDistanceSquared = distanceSquared
		end
	end

	return ClosestPlayer, closestDistanceSquared
end
local function checkIfBallIsTouchingPlayer(soccerBallId, Player)
	if SoccerBallIdToPossessingPlayer[Player] then
		return
	end

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	if SoccerBallPart == nil then
		return
	end

	local playerPosition = Utility.getPlayerCharacterPosition(Player)
	if playerPosition == nil then
		return
	end

	local offset = playerPosition - SoccerBallPart.Position
	if offset:Dot(offset) > MAX_DISTANCE_TO_POSSESS ^ 2 then
		return
	end

	givePlayerSoccerBallOwnership(Player, soccerBallId)
end
local function checkIfGoalScoredBallIsReadyToDestroy(soccerBallId, timestamp)
	timestamp = timestamp or SoccerBallIdToGoalDestroyTimestamp[soccerBallId]

	local now = Time.getUnixTimestampMilliseconds()
	if now < timestamp then
		return
	end

	destroySoccerBall(soccerBallId)
end
local function getGoalBallIsIn(soccerBallId)
	local mapId = SoccerBallIdToMapId[soccerBallId]
	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]

	local mapName = MapsServer.getMapInstanceMapName(mapId)
	local MapFolder = MapsServer.getMapInstanceFolder(mapId)

	local Team1GoalPart = Assets.getExpectedAsset(`{mapName} Team1 GoalPart`, `{mapName} MapFolder`, MapFolder)
	if Utility.positionIsInPart(SoccerBallPart.Position, Team1GoalPart) then
		return 1
	end

	local Team2GoalPart = Assets.getExpectedAsset(`{mapName} Team2 GoalPart`, `{mapName} MapFolder`, MapFolder)
	if Utility.positionIsInPart(SoccerBallPart.Position, Team2GoalPart) then
		return 2
	end
end
local function checkIfBallScoredGoal(soccerBallId)
	if SoccerBallIdToGoalDestroyTimestamp[soccerBallId] then
		return
	end

	local PreviousPossessingPlayer = SoccerBallIdToPreviousPossessingPlayer[soccerBallId]
	if PreviousPossessingPlayer == nil then
		return
	end

	local goalTeamIndex = getGoalBallIsIn(soccerBallId)
	if goalTeamIndex == nil then
		return
	end

	local playerTeamIndex = MapsServer.getPlayerTeamIndex(PreviousPossessingPlayer)
	if goalTeamIndex == playerTeamIndex or playerTeamIndex == nil then
		return
	end

	MapsServer.playerScoredGoal(PreviousPossessingPlayer)

	local now = Time.getUnixTimestampMilliseconds()
	SoccerBallIdToGoalDestroyTimestamp[soccerBallId] = now + SECONDS_AFTER_GOAL_BALL_IS_DESTROYED * 1E3

	if PossessingPlayerToBallId[PreviousPossessingPlayer] == soccerBallId then
		removePlayerSoccerBallOwnership(PreviousPossessingPlayer, soccerBallId)
	end
end

local function getNewSoccerBallId()
	numSoccerBallsCreated += 1
	return numSoccerBallsCreated
end

-- public
local function teleportSoccerBallToPosition(soccerBallId, position)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end
	if not (typeof(position) == "Vector3") then
		error(`{position} is not a Vector3!`)
	end

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	local mapId = SoccerBallIdToMapId[soccerBallId]
	if SoccerBallPart == nil or mapId == nil then
		return
	end

	SoccerBallPart.Position = position

	local Player, distanceSquared = getClosestUnpossessingPlayerToPosition(mapId, position)
	if Player == nil then
		return
	end

	if distanceSquared > MAX_DISTANCE_TO_POSSESS ^ 2 then
		return
	end

	givePlayerSoccerBallOwnership(Player, soccerBallId)
end
local function checkIfPlayerIsTouchingABall(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local characterPosition = Utility.getPlayerCharacterPosition(Player)
	if characterPosition == nil then
		return
	end

	local closestBallId, distanceSquared = getClosestUnpossessedBallIdToPosition(characterPosition)
	if closestBallId == nil then
		return
	end

	if distanceSquared > MAX_DISTANCE_TO_POSSESS ^ 2 then
		return
	end

	givePlayerSoccerBallOwnership(Player, closestBallId)
end
local function soccerPhysicsStep(deltaTime)
	if not TESTING_MODE then
		error(`soccerPhysicsStep() is only for use in TESTING_MODE`)
	end

	for soccerBallId, SoccerBallPart in SoccerBallIdToPart do
		if SoccerBallIdToPossessingPlayer[soccerBallId] then
			continue
		end

		SoccerBallPart.Position += SoccerBallPart.Velocity * deltaTime

		checkIfBallScoredGoal(soccerBallId)
	end
end
local function playerKickSoccerBall(PossessingPlayer, direction, speed)
	if not (Utility.isA(PossessingPlayer, "Player")) then
		error(`{PossessingPlayer} is not a Player!`)
	end
	if not (typeof(direction) == "Vector3") then
		error(`{direction} is not a Vector3!`)
	end
	if not (typeof(speed) == "number") then
		error(`{speed} is not a number!`)
	end

	local soccerBallId = PossessingPlayerToBallId[PossessingPlayer]
	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	if soccerBallId == nil or SoccerBallPart == nil then
		return
	end

	removePlayerSoccerBallOwnership(PossessingPlayer, soccerBallId)

	direction = direction.Unit
	speed = math.clamp(speed, MIN_SOCCER_BALL_KICK_SPEED, MAX_SOCCER_BALL_KICK_SPEED)

	SoccerBallPart.AssemblyLinearVelocity = speed * direction
end
local function checkIfPlayerDribbledBallIntoGoal(PossessingPlayer)
	local soccerBallId = PossessingPlayerToBallId[PossessingPlayer]
	if soccerBallId == nil then
		return
	end

	checkIfBallScoredGoal(soccerBallId)
end
local function soccerBallStateTick()
	for soccerBallId, destroyTimestamp in SoccerBallIdToGoalDestroyTimestamp do
		checkIfGoalScoredBallIsReadyToDestroy(soccerBallId, destroyTimestamp)
	end
end
local function getPlayerPossessedBallId(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return PossessingPlayerToBallId[Player]
end
local function getSoccerBallParentMapId(soccerBallId)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end

	return SoccerBallIdToMapId[soccerBallId]
end
local function getSoccerBallPosition(soccerBallId)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	if SoccerBallPart == nil then
		return nil
	end

	return SoccerBallPart.Position
end
local function getSoccerBallOwner(soccerBallId)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end

	return SoccerBallIdToPossessingPlayer[soccerBallId]
end
local function getSoccerBallState(soccerBallId)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	if SoccerBallPart == nil then
		return "Destroyed"
	end

	if SoccerBallIdToGoalDestroyTimestamp[soccerBallId] then
		return "Goal"
	end

	local PossessingPlayer = SoccerBallIdToPossessingPlayer[soccerBallId]
	if PossessingPlayer then
		return "Possessed"
	end

	return "Idle"
end
function destroySoccerBall(soccerBallId)
	if not Utility.isInteger(soccerBallId) then
		error(`{soccerBallId} is not an integer!`)
	end

	local SoccerBallPart = SoccerBallIdToPart[soccerBallId]
	if SoccerBallPart == nil then
		return
	end

	local PossessingPlayer = SoccerBallIdToPossessingPlayer[soccerBallId]
	if PossessingPlayer then
		removePlayerSoccerBallOwnership(PossessingPlayer, soccerBallId)
	end

	SoccerBallIdToPart[soccerBallId] = nil
	SoccerBallIdToMapId[soccerBallId] = nil
	SoccerBallIdToGoalDestroyTimestamp[soccerBallId] = nil
	SoccerBallIdToPreviousPossessingPlayer[soccerBallId] = nil

	SoccerBallPart:Destroy()
end
local function newSoccerBall(mapId, PossessingPlayer)
	local MapFolder = MapsServer.getMapInstanceFolder(mapId)
	local mapState = MapsServer.getMapInstanceState(mapId)
	local mapName = MapsServer.getMapInstanceMapName(mapId)

	if MapFolder == nil then
		error(`Map {mapId} has no folder`)
	end
	if not (mapState == "Gameplay" or mapState == "MatchGameplay") then
		error(`{mapState} is not 'Gameplay' or 'MatchGameplay'!`)
	end

	if PossessingPlayer ~= nil then
		if not (Utility.isA(PossessingPlayer, "Player")) then
			error(`{PossessingPlayer} is not a Player!`)
		end
		if PossessingPlayerToBallId[PossessingPlayer] then
			error(`{PossessingPlayer} already possesses ball {PossessingPlayerToBallId[PossessingPlayer]}`)
		end
		if Utility.getPlayerCharacterCFrame(PossessingPlayer) == nil then
			error(`{PossessingPlayer} has no CFrame`)
		end
	end

	local soccerBallId = getNewSoccerBallId()

	local Part = Instance.new("Part")
	Part.Shape = Enum.PartType.Ball
	Part.Size = Vector3.new(2, 2, 2)
	Part.Color = Color3.new(1, 1, 1)
	Part.Name = `Ball{soccerBallId}`

	if PossessingPlayer == nil then
		local SoccerBallSpawnPart =
			Assets.getExpectedAsset(`{mapName} BallSpawnPoint`, `{mapName} MapFolder`, MapFolder)
		Part.CFrame = SoccerBallSpawnPart.CFrame
	end

	Part.Parent = workspace

	SoccerBallIdToPart[soccerBallId] = Part
	SoccerBallIdToMapId[soccerBallId] = mapId

	if PossessingPlayer then
		givePlayerSoccerBallOwnership(PossessingPlayer, soccerBallId)
	end

	return soccerBallId
end
local function initializeSoccerBallServer()
	SoccerBallsFolder = Instance.new("Folder")
	SoccerBallsFolder.Name = "SoccerBalls"
	SoccerBallsFolder.Parent = workspace

	Network.onServerEventConnect("PlayerKickSoccerBall", playerKickSoccerBall)
end

return {
	checkIfPlayerIsTouchingABall = checkIfPlayerIsTouchingABall,
	teleportSoccerBallToPosition = teleportSoccerBallToPosition,
	getPlayerPossessedBallId = getPlayerPossessedBallId,
	getSoccerBallParentMapId = getSoccerBallParentMapId,
	getSoccerBallPosition = getSoccerBallPosition,
	playerKickSoccerBall = playerKickSoccerBall,
	soccerBallStateTick = soccerBallStateTick,
	getSoccerBallOwner = getSoccerBallOwner,
	getSoccerBallState = getSoccerBallState,
	soccerPhysicsStep = soccerPhysicsStep,
	destroySoccerBall = destroySoccerBall,
	newSoccerBall = newSoccerBall,

	checkIfPlayerDribbledBallIntoGoal = checkIfPlayerDribbledBallIntoGoal,
	initialize = initializeSoccerBallServer,
}
