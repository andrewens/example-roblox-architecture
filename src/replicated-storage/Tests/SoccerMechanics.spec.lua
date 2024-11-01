-- dependency
local TestsFolder = script:FindFirstAncestor("Tests")

local Actions = require(TestsFolder.Actions)
local Assert = require(TestsFolder.Assert)

-- const
local TOTAL_NUM_TESTS = 5

-- var
local numTestsRun = 0
local testMapId
local Client1, Client2, Client3, Client4

-- private
local function beginTest()
	numTestsRun += 1

	if testMapId == nil then
		testMapId, Client1, Client2, Client3, Client4 = Actions.initializeMapForPlay()
	end
end
local function endTest()
	if numTestsRun < TOTAL_NUM_TESTS then
		return
	end

	Actions.destroyMap(testMapId, Client1, Client2, Client3, Client4)
end

return function()
	describe("Soccerball state, kicking & possession mechanics", function()
		-- TODO can you make the code functional so you don't have to worry about state? It's causing problems to have to think about previous state
		-- TODO need to figure out a framework for physics testing + a framework for roblox characters
		-- TODO could we organize imperative code in layers, like: side effects layer, network replication layer, core state layer?
		-- and then every function is its own file, or we just have big files of functions where every function can invoke any other
		-- function in its layer, plus any lower-level layer function, so that way we don't have to make new modules each time.
		-- and similarly the testing code could have layers of state assertions, actions, and tests (and maybe each state could have an ID)
		-- and then we could use a graph diagram generator to visualize the system layout and all of the spec states

		-- TODO test out of bounds zone
		-- TODO test if a player disconnects
		-- TODO test if a player disconnects after shooting a goal

		it("SoccerDuels API can create and destroy soccer ball instances", function()
			beginTest()

			Assert.mapIsReadyForPlay(testMapId)

			local ballId = Actions.spawnBallInCenterOfMap(testMapId)
			Assert.soccerBallIsIdle(testMapId, ballId)
			Assert.soccerBallIsAtDefaultSpawnPoint(testMapId, ballId)

			Actions.destroySoccerBall(testMapId, ballId)
			Assert.soccerBallIsDestroyed(testMapId, ballId)

			endTest()
		end)
		it("Destroying a soccerball while player possesses it just removes it from the world", function()
			beginTest()

			Assert.mapIsReadyForPlay(testMapId)

			ballId = Actions.spawnBallAtPlayer(testMapId, Client1.Player)
			Assert.soccerBallIsPossessedByPlayer(testMapId, ballId, Client1.Player)

			Actions.destroySoccerBall(testMapId, ballId)
			Assert.soccerBallIsDestroyed(testMapId, ballId)

			endTest()
		end)
		it("Players can walk a possessed ball into the goal to score", function()
			beginTest()

			Assert.mapIsReadyForPlay(testMapId)

			ballId = Actions.spawnBallAtPlayer(testMapId, Client2.Player)
			Assert.soccerBallIsPossessedByPlayer(testMapId, ballId, Client2.Player)

			Actions.movePlayerToOpposingGoalPosition(testMapId, Client2.Player)
			Assert.soccerBallIsInPlayersOpposingGoal(testMapId, ballId, Client2.Player)
			Assert.playerScoredGoal(testMapId, Client2.Player)

			Actions.waitForSoccerBallInGoalToDestroy(testMapId, ballId)
			Assert.soccerBallIsDestroyed(testMapId, ballId)

			endTest()
		end)
		it("Players can kick a possessed ball into the goal to score", function()
			beginTest()

			Actions.mapWaitForNextRound(testMapId)
			Assert.mapIsReadyForPlay(testMapId)

			ballId = Actions.spawnBallAtPlayer(testMapId, Client3.Player)
			Assert.soccerBallIsPossessedByPlayer(testMapId, ballId, Client3.Player)

			Actions.playerKickSoccerBallIntoOpposingGoal(testMapId, Client3.Player)
			Assert.soccerBallIsInPlayersOpposingGoal(testMapId, ballId, Client3.Player)
			Assert.playerScoredGoal(testMapId, Client3.Player)

			Actions.waitForSoccerBallInGoalToDestroy(testMapId, ballId)
			Assert.soccerBallIsDestroyed(testMapId, ballId)

			endTest()
		end)
		it("Players lose possession of a ball after they kick it", function()
			beginTest()

			Actions.mapWaitForNextRound(testMapId)
			Assert.mapIsReadyForPlay(testMapId)

			ballId = Actions.spawnBallInCenterOfMap(testMapId)
			Assert.soccerBallIsAtDefaultSpawnPoint(testMapId, ballId)

			Actions.movePlayerToSoccerBallPosition(testMapId, ballId, Client4.Player) -- (possess ball by walking to it)
			Assert.playerPossessesSoccerBall(testMapId, ballId, Client4.Player)

			Actions.movePlayerInSomeDirection(testMapId, Client4.Player) -- dribble
			Assert.playerPossessesSoccerBall(testMapId, ballId, Client4.Player)

			Actions.playerKickSoccerBallServer(testMapId, Client4.Player) -- server kick
			Assert.noOnePossessesSoccerBall(testMapId, ballId)

			Actions.moveSoccerBallToPlayersPosition(testMapId, ballId, Client4.Player) -- (repossess ball by teleporting it to player)
			Assert.playerPossessesSoccerBall(testMapId, ballId, Client4.Player)

			Actions.playerKickSoccerBallClient(testMapId, Client4) -- client kick
			Assert.noOnePossessesSoccerBall(testMapId, ballId)

			Actions.destroySoccerBall(testMapId, ballId)
			Assert.soccerBallIsDestroyed(testMapId, ballId)

			endTest()
		end)
	end)
end
