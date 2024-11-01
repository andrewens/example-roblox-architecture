-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- public / Vector3 state
local function assertPositionIsInsideOfPart(position, Part)
	local partPosition = Part.Position
	local partCFrame = Part.CFrame
	local offset = position - partPosition

	local x = offset:Dot(partCFrame.RightVector)
	local y = offset:Dot(partCFrame.UpVector)
	local z = offset:Dot(partCFrame.LookVector)

	assert(math.abs(x) <= Part.Size.X)
	assert(math.abs(y) <= Part.Size.Y)
	assert(math.abs(z) <= Part.Size.Z)
end

-- public / Soccerball state
local function assertNoOnePossessesSoccerBall(mapId, ballId)
	if not (SoccerDuels.getSoccerBallOwner(ballId) == nil) then
		error(`{SoccerDuels.getSoccerBallOwner(ballId)} != nil`)
	end

	for Player, teamIndex in SoccerDuels.getPlayersConnectedToMapInstance(mapId) do
		assert(SoccerDuels.getPlayerPossessedBallId(Player) == nil)
	end
end
local function assertPlayerPossessesSoccerBall(mapId, ballId, Player)
	if not (SoccerDuels.getPlayerPossessedBallId(Player) == ballId) then
		error(`{SoccerDuels.getPlayerPossessedBallId(Player)} != {ballId}`)
	end
	assert(SoccerDuels.getSoccerBallOwner(ballId) == Player)

	for OtherPlayer, teamIndex in SoccerDuels.getPlayersConnectedToMapInstance(mapId) do
		if OtherPlayer == Player then
			continue
		end

		assert(SoccerDuels.getPlayerPossessedBallId(OtherPlayer) ~= ballId)
	end
end
local function assertPlayerScoredGoal(mapId, Player, prevGoals)
	prevGoals = prevGoals or 0

	assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")
	assert(SoccerDuels.getPlayerThatScoredLastGoal(mapId) == Player)
	assert(SoccerDuels.getCachedPlayerSaveData(Player).Goals == prevGoals + 1)
end
local function assertPlayerIsNotNearSoccerBallSpawnPoint(mapId, Player)
	local MapFolder = SoccerDuels.getMapInstanceFolder(mapId)
	local mapName = SoccerDuels.getMapInstanceMapName(mapId)

	local playerPosition = SoccerDuels.getPlayerPosition(Player)
	local spawnPosition =
		SoccerDuels.getExpectedAsset(`{mapName} BallSpawnPoint`, `{mapName} MapFolder`, MapFolder).Position
	local offset = playerPosition - spawnPosition
	local minDistance = 5 -- ?

	assert(offset:Dot(offset) >= minDistance ^ 2)
end
local function assertSoccerBallIsAtDefaultSpawnPoint(mapId, ballId)
	local MapFolder = SoccerDuels.getMapInstanceFolder(mapId)
	local mapName = SoccerDuels.getMapInstanceMapName(mapId)

	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	local spawnPosition =
		SoccerDuels.getExpectedAsset(`{mapName} BallSpawnPoint`, `{mapName} MapFolder`, MapFolder).Position

	assert(ballPosition:FuzzyEq(spawnPosition))
end
local function assertSoccerBallIsNearPlayer(mapId, ballId, Player)
	local ballOffset = SoccerDuels.getConstant("SoccerBallWeldOffsetLocalCoordinates")

	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	local playerCFrame = SoccerDuels.getPlayerCFrame(Player)

	local correctBallPosition = playerCFrame.Position
		+ playerCFrame.RightVector * ballOffset.X
		+ playerCFrame.UpVector * ballOffset.Y
		+ playerCFrame.LookVector * ballOffset.Z

	assert(correctBallPosition:FuzzyEq(ballPosition))
end
local function assertSoccerBallIsIdle(mapId, ballId)
	assert(SoccerDuels.getSoccerBallParentMapId(ballId) == mapId)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Idle")

	assertNoOnePossessesSoccerBall(mapId, ballId)
end
local function assertSoccerBallIsDestroyed(mapId, ballId)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Destroyed")
	assertNoOnePossessesSoccerBall(mapId, ballId)
end
local function assertSoccerBallIsPossessedByPlayer(mapId, ballId, Player)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Possessed")
	assert(SoccerDuels.getSoccerBallParentMapId(ballId) == mapId)
	assert(SoccerDuels.getSoccerBallOwner(ballId) == Player)
	assert(SoccerDuels.getPlayerPossessedBallId(Player) == ballId)

	assertSoccerBallIsNearPlayer(mapId, ballId, Player)
end
--[[ this state might be necessary to prevent instant repossessing by players that kick
local function soccerBallHasJustBeenKicked(mapId, ballId, PlayerThatKicked)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Kicked")

	noOnePossessesSoccerBall(mapId, ballId)

    -- TODO maybe test that the player who just kicked the ball can't repossess it instantly if necessary
end--]]
local function assertSoccerBallIsInPlayersOpposingGoal(mapId, ballId, Player)
	if not (SoccerDuels.getSoccerBallState(ballId) == "Goal") then
		error(`{SoccerDuels.getSoccerBallState(ballId)} != "Goal"`)
	end
	assertNoOnePossessesSoccerBall(mapId, ballId)

	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	local teamIndex = SoccerDuels.getPlayerTeamIndex(Player)
	local otherTeamIndex = if teamIndex == 1 then 2 else 1

	local mapName = SoccerDuels.getMapInstanceMapName(mapId)
	local MapFolder = SoccerDuels.getMapInstanceFolder(mapId)
	local GoalPart =
		SoccerDuels.getExpectedAsset(`{mapName} Team{otherTeamIndex} GoalPart`, `{mapName} MapFolder`, MapFolder)

	assertPositionIsInsideOfPart(ballPosition, GoalPart)
end

-- public / Map state
local function assertMapIsReadyForPlay(mapId)
	local Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId)

	assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")
	assert(Utility.tableCount(Players) == 4)

	for Player, _ in Players do
		assertPlayerIsNotNearSoccerBallSpawnPoint(mapId, Player)
	end
end

return {
	positionIsInsideOfPart = assertPositionIsInsideOfPart,
	noOnePossessesSoccerBall = assertNoOnePossessesSoccerBall,
	playerPossessesSoccerBall = assertPlayerPossessesSoccerBall,
	playerScoredGoal = assertPlayerScoredGoal,
	playerIsNotNearSoccerBallSpawnPoint = assertPlayerIsNotNearSoccerBallSpawnPoint,
	soccerBallIsAtDefaultSpawnPoint = assertSoccerBallIsAtDefaultSpawnPoint,
	soccerBallIsNearPlayer = assertSoccerBallIsNearPlayer,
	soccerBallIsIdle = assertSoccerBallIsIdle,
	soccerBallIsDestroyed = assertSoccerBallIsDestroyed,
	soccerBallIsPossessedByPlayer = assertSoccerBallIsPossessedByPlayer,
	soccerBallIsInPlayersOpposingGoal = assertSoccerBallIsInPlayersOpposingGoal,
	mapIsReadyForPlay = assertMapIsReadyForPlay,
}
