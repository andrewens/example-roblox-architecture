-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- public / Map actions
local function initializeMapForPlay()
	SoccerDuels.resetTestingVariables()
	SoccerDuels.disconnectAllPlayers()

	local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
	local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")

	local Player1 = MockInstance.new("Player")
	local Player2 = MockInstance.new("Player")
	local Player3 = MockInstance.new("Player")
	local Player4 = MockInstance.new("Player")

	local Client1 = SoccerDuels.newClient(Player1)
	local Client2 = SoccerDuels.newClient(Player2)
	local Client3 = SoccerDuels.newClient(Player3)
	local Client4 = SoccerDuels.newClient(Player4)

	Client1:LoadPlayerDataAsync()
	Client2:LoadPlayerDataAsync()
	Client3:LoadPlayerDataAsync()
	Client4:LoadPlayerDataAsync()

	local mapId = SoccerDuels.newMapInstance("Stadium")

	SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 1)
	SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 1)
	SoccerDuels.connectPlayerToMapInstance(Player3, mapId, 2)
	SoccerDuels.connectPlayerToMapInstance(Player4, mapId, 2)

	SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration)
	SoccerDuels.mapTimerTick()
	SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration)
	SoccerDuels.mapTimerTick()

	return mapId, Client1, Client2, Client3, Client4
end
local function destroyMap(mapId, Client1, Client2, Client3, Client4)
	SoccerDuels.destroyMapInstance(mapId)
	Client1:Destroy()
	Client2:Destroy()
	Client3:Destroy()
	Client4:Destroy()
end
local function mapWaitForNextRound(mapId)
	if SoccerDuels.getMapInstanceState(mapId) == "MatchOver" then
		local duration = SoccerDuels.getConstant("MatchOverDurationSeconds")

		SoccerDuels.addExtraSecondsForTesting(duration)
		SoccerDuels.mapTimerTick()
	end

	if SoccerDuels.getMapInstanceState(mapId) == "GoalCutscene" then
		local duration = SoccerDuels.getConstant("GoalCutsceneDurationSeconds")

		SoccerDuels.addExtraSecondsForTesting(duration)
		SoccerDuels.mapTimerTick()
	end

	if SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown" then
		local duration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")

		SoccerDuels.addExtraSecondsForTesting(duration)
		SoccerDuels.mapTimerTick()
	end
end

-- public / SoccerBall actions
local function spawnBallInCenterOfMap(mapId)
	return SoccerDuels.newSoccerBall(mapId)
end
local function spawnBallAtPlayer(mapId, Player)
	return SoccerDuels.newSoccerBall(mapId, Player)
end
local function waitForSoccerBallInGoalToDestroy(mapId, ballId)
	local secondsAfterGoalBallIsDestroyed = SoccerDuels.getConstant("SecondsAfterGoalBallIsDestroyed")

	SoccerDuels.addExtraSecondsForTesting(secondsAfterGoalBallIsDestroyed)
	SoccerDuels.soccerBallStateTick()
end
local function destroySoccerBall(mapId, ballId)
	SoccerDuels.destroySoccerBall(ballId)
end

-- public / Player actions
local function movePlayerToOpposingGoalPosition(mapId, Player)
	local teamIndex = SoccerDuels.getPlayerTeamIndex(Player)
	local otherTeamIndex = if teamIndex == 1 then 2 else 1

	local mapName = SoccerDuels.getMapInstanceMapName(mapId)
	local MapFolder = SoccerDuels.getMapInstanceFolder(mapId)
	local GoalPart =
		SoccerDuels.getExpectedAsset(`{mapName} Team{otherTeamIndex} GoalPart`, `{mapName} MapFolder`, MapFolder)

	SoccerDuels.teleportPlayerToPosition(Player, GoalPart.Position)
end
local function movePlayerInSomeDirection(mapId, Player)
	local playerPosition = SoccerDuels.getPlayerPosition(Player)
	local offset = Vector3.new(5, 0, 5)

	SoccerDuels.teleportPlayerToPosition(Player, playerPosition + offset)
end
local function playerKickSoccerBallIntoOpposingGoal(mapId, Player)
	local teamIndex = SoccerDuels.getPlayerTeamIndex(Player)
	local otherTeamIndex = if teamIndex == 1 then 2 else 1

	local mapName = SoccerDuels.getMapInstanceMapName(mapId)
	local MapFolder = SoccerDuels.getMapInstanceFolder(mapId)
	local GoalPart =
		SoccerDuels.getExpectedAsset(`{mapName} Team{otherTeamIndex} GoalPart`, `{mapName} MapFolder`, MapFolder)
	local NearGoalPart =
		SoccerDuels.getExpectedAsset(`{mapName} Team{teamIndex} GoalKickTestingPart`, `{mapName} MapFolder`, MapFolder)

	local direction = GoalPart.Position - NearGoalPart.Position -- should get turned into unit vector

	local initialDistanceFromBallToGoal = 10 -- this accounts for the edge of the goal zone, and should be updated when GoalKickTestingPart is updated
	local deltaTime = 0.1
	local power = initialDistanceFromBallToGoal / deltaTime -- power is actually just the initial velocity of the ball

	SoccerDuels.teleportPlayerToPosition(Player, NearGoalPart.Position)
	SoccerDuels.playerKickSoccerBall(Player, direction, power)
	SoccerDuels.soccerPhysicsStep(deltaTime)
end
local function playerKickSoccerBallServer(mapId, Player)
	local direction = Vector3.new(1, 0, 0)
	local power = 10

	SoccerDuels.playerKickSoccerBall(Player, direction, power)
end
local function playerKickSoccerBallClient(mapId, Client)
	local direction = Vector3.new(1, 0, 0)
	local power = 10

	Client:KickSoccerBall(direction, power)
end

-- public / Player-Soccerball actions
local function moveSoccerBallToPlayersPosition(mapId, ballId, Player)
	local playerPosition = SoccerDuels.getPlayerPosition(Player)
	SoccerDuels.teleportSoccerBallToPosition(ballId, playerPosition)
end
local function movePlayerToSoccerBallPosition(mapId, ballId, Player)
	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	SoccerDuels.teleportPlayerToPosition(Player, ballPosition)
end

return {
	initializeMapForPlay = initializeMapForPlay,
	destroyMap = destroyMap,
	mapWaitForNextRound = mapWaitForNextRound,

	spawnBallInCenterOfMap = spawnBallInCenterOfMap,
	spawnBallAtPlayer = spawnBallAtPlayer,
	waitForSoccerBallInGoalToDestroy = waitForSoccerBallInGoalToDestroy,
	destroySoccerBall = destroySoccerBall,

	movePlayerToOpposingGoalPosition = movePlayerToOpposingGoalPosition,
	movePlayerInSomeDirection = movePlayerInSomeDirection,
	playerKickSoccerBallIntoOpposingGoal = playerKickSoccerBallIntoOpposingGoal,
	playerKickSoccerBallServer = playerKickSoccerBallServer,
	playerKickSoccerBallClient = playerKickSoccerBallClient,

	moveSoccerBallToPlayersPosition = moveSoccerBallToPlayersPosition,
	movePlayerToSoccerBallPosition = movePlayerToSoccerBallPosition,
}
