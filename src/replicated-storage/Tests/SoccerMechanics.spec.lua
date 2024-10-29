-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- private / states
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

local function assertNoOnePossessesSoccerBall(mapId, ballId)
	assert(SoccerDuels.getSoccerBallOwner(ballId) == nil)

	for Player, teamIndex in SoccerDuels.getPlayersConnectedToMapInstance(mapId) do
		assert(SoccerDuels.getPlayerPossessedBallId(Player) == nil)
	end
end
local function assertPlayerPossessesSoccerBall(mapId, ballId, Player)
	assert(SoccerDuels.getPlayerPossessedBallId(Player) == ballId)
	assert(SoccerDuels.getSoccerBallOwner(ballId) == Player)

	for OtherPlayer, teamIndex in SoccerDuels.getPlayersConnectedToMapInstance(mapId) do
		if OtherPlayer == Player then
			continue
		end

		assert(SoccerDuels.getPlayerPossessedBallId(Player) == nil)
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

	local playerPosition = SoccerDuels.getSoccerBallPosition(Player)
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
	local maxPossessionDistance = 3

	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	local playerPosition = SoccerDuels.getPlayerPosition(Player)
	local offset = ballPosition - playerPosition

	assert(offset:Dot(offset) <= maxPossessionDistance ^ 2)
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

	assertSoccerBallIsIdle(mapId, ballId, Player)
	assertSoccerBallIsNearPlayer(mapId, ballId, Player)
end
--[[ this state might be necessary to prevent instant repossessing by players that kick
local function soccerBallHasJustBeenKicked(mapId, ballId, PlayerThatKicked)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Kicked")

	noOnePossessesSoccerBall(mapId, ballId)

    -- TODO maybe test that the player who just kicked the ball can't repossess it instantly if necessary
end--]]
local function assertSoccerBallIsInPlayersOpposingGoal(mapId, ballId, Player)
	assert(SoccerDuels.getSoccerBallState(ballId) == "Goal")
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

local function assertMapIsReadyForPlay(mapId)
	local Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId)

	assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")
	assert(Utility.tableCount(Players) == 4)

	for Player, _ in Players do
		assertPlayerIsNotNearSoccerBallSpawnPoint(mapId, Player)
	end
end

-- private / actions (mutate one state to another state)
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

local function spawnBallInCenterOfMap(mapId)
	return SoccerDuels.newSoccerBall(mapId)
end
local function spawnBallAtPlayer(mapId, Player)
	return SoccerDuels.newSoccerBall(mapId, Player)
end
local function waitForSoccerBallInGoalToDestroy(mapId, ballId)
	local secondsAfterGoalBallIsDestroyed = SoccerDuels.getConstant("SecondsAfterGoalBallIsDestroyed")

	SoccerDuels.addExtraSecondsForTesting(secondsAfterGoalBallIsDestroyed)
	SoccerDuels.mapTimerTick()
end
local function moveSoccerBallToPlayersPosition(mapId, ballId, Player)
	local playerPosition = SoccerDuels.getPlayerPosition(Player)
	SoccerDuels.teleportSoccerBallToPosition(playerPosition)
end
local function destroySoccerBall(mapId, ballId)
	SoccerDuels.destroySoccerBall(ballId)
end

local function movePlayerToSoccerBallPosition(mapId, ballId, Player)
	local ballPosition = SoccerDuels.getSoccerBallPosition(ballId)
	SoccerDuels.teleportPlayerToPosition(Player, ballPosition)
end
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
	local NearGoalPart = SoccerDuels.getExpectedAsset(
		`{mapName} Team{otherTeamIndex} GoalKickTestingPart`,
		`{mapName} MapFolder`,
		MapFolder
	)

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

return function()
	itFOCUS("Soccerball state, kicking & possession mechanics", function()
		-- TODO does TestEZ support pre-test and post-test hooks?
		-- TODO can you make the code functional so you don't have to worry about state? It's causing problems to have to think about previous state
		-- TODO need to figure out a framework for physics testing + a framework for roblox characters
		-- TODO could we organize imperative code in layers, like: side effects layer, network replication layer, core state layer?
		-- and then every function is its own file, or we just have big files of functions where every function can invoke any other
		-- function in its layer, plus any lower-level layer function, so that way we don't have to make new modules each time.
		-- and similarly the testing code could have layers of state assertions, actions, and tests (and maybe each state could have an ID)
		-- and then we could use a graph diagram generator to visualize the system layout and all of the spec states

        -- TODO test out of bounds zone

		local mapId, Client1, Client2, Client3, Client4 = initializeMapForPlay()

		-- test #1 | create & destroy a soccer ball
		assertMapIsReadyForPlay(mapId)

		local ballId = spawnBallInCenterOfMap(mapId)
		assertSoccerBallIsAtDefaultSpawnPoint(mapId, ballId)

		destroySoccerBall(mapId, ballId)
		assertSoccerBallIsDestroyed(mapId, ballId)

		-- test #2 | destroy a soccer ball while player possesses it
		assertMapIsReadyForPlay(mapId)

		ballId = spawnBallAtPlayer(mapId, Client1.Player)
		assertSoccerBallIsPossessedByPlayer(mapId, ballId, Client1.Player)

		destroySoccerBall(mapId, ballId)
		assertSoccerBallIsDestroyed(mapId, ballId)

		-- test #3 | player dribbles soccer ball into goal
		assertMapIsReadyForPlay(mapId)

		ballId = spawnBallAtPlayer(mapId, Client2.Player)
		assertSoccerBallIsPossessedByPlayer(mapId, ballId, Client2.Player)

		movePlayerToOpposingGoalPosition(mapId, Client2.Player)
		assertSoccerBallIsInPlayersOpposingGoal(mapId, ballId, Client2.Player)
		assertPlayerScoredGoal(mapId, Client2.Player)

		waitForSoccerBallInGoalToDestroy(mapId, ballId)
		assertSoccerBallIsDestroyed(mapId, ballId)

		-- test #4 | player kicks soccer ball into goal
		mapWaitForNextRound(mapId)
		assertMapIsReadyForPlay(mapId)

		ballId = spawnBallAtPlayer(mapId, Client3.Player)
		assertSoccerBallIsPossessedByPlayer(mapId, ballId, Client3.Player)

		playerKickSoccerBallIntoOpposingGoal(mapId, Client3.Player)
		assertSoccerBallIsInPlayersOpposingGoal(mapId, ballId, Client3.Player)
		assertPlayerScoredGoal(mapId, Client3.Player)

		waitForSoccerBallInGoalToDestroy(mapId, ballId)
		assertSoccerBallIsDestroyed(mapId, ballId)

		-- test #5 | player possesses and dispossesses ball as they kick it and run back to it
		mapWaitForNextRound(mapId)
		assertMapIsReadyForPlay(mapId)

		ballId = spawnBallInCenterOfMap(mapId)
		assertSoccerBallIsAtDefaultSpawnPoint(mapId, ballId)

		movePlayerToSoccerBallPosition(mapId, ballId, Client4.Player) -- (possess ball by walking to it)
		assertPlayerPossessesSoccerBall(mapId, ballId, Client4.Player)

		movePlayerInSomeDirection(mapId, Client4.Player) -- dribble
		assertPlayerPossessesSoccerBall(mapId, ballId, Client4.Player)

		playerKickSoccerBallServer(mapId, Client4.Player) -- server kick
		assertNoOnePossessesSoccerBall(mapId, ballId)

		moveSoccerBallToPlayersPosition(mapId, ballId, Client4.Player) -- (repossess ball by teleporting it to player)
		assertPlayerPossessesSoccerBall(mapId, ballId, Client4.Player)

		playerKickSoccerBallClient(mapId, Client4) -- client kick
		assertNoOnePossessesSoccerBall(mapId, ballId)

		destroySoccerBall(mapId, ballId)
		assertSoccerBallIsDestroyed(mapId, ballId)

		-- cleanup
		destroyMap(mapId, Client1, Client2, Client3, Client4)
	end)
end
