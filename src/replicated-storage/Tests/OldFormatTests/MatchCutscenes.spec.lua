-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	it("Clients remember the position & orientation of players for the goal cutscene", function()
		SoccerDuels.disconnectAllPlayers()
		SoccerDuels.destroyAllMapInstances()
		SoccerDuels.resetTestingVariables()

		local maxError = 0.010
		local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
		local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
		local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
		local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
		local goalCutsceneDuration = SoccerDuels.getConstant("GoalCutsceneDurationSeconds")
		local secondsAfterGoalUntilCutsceneEnds = SoccerDuels.getConstant("SecondsAfterGoalUntilGoalCutsceneEnds")
		local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
		local cutsceneFramesPerSecond = SoccerDuels.getConstant("GoalCutsceneFramesPerSecond")

		local totalNumFrames = cutsceneFramesPerSecond * goalCutsceneDuration
		local cutsceneSecondsPerFrame = 1 / cutsceneFramesPerSecond

		assert(secondsAfterGoalUntilCutsceneEnds < goalCutsceneDuration)

		-- create players
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

		-- create map
		local mapId = SoccerDuels.newMapInstance("Stadium")

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 1)
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 2)
		SoccerDuels.connectPlayerToMapInstance(Player3, mapId, 1)
		SoccerDuels.connectPlayerToMapInstance(Player4, mapId, 2)

		SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

		SoccerDuels.addExtraSecondsForTesting(0.1) -- extra seconds in match gameplay
		SoccerDuels.mapTimerTick()

		local TestCFrames = {} -- int frameIndex --> Player --> CFrame
		local frameAtWhichPlayer4Disconnects = 10
		local frameAtWhichPlayerScoresGoal = math.floor(
			(goalCutsceneDuration - secondsAfterGoalUntilCutsceneEnds + cutsceneSecondsPerFrame)
				* cutsceneFramesPerSecond
		)

		for i = 1, totalNumFrames do
			TestCFrames[i] = {
				[Player1] = CFrame.new(i, i, i), -- these are just random cframes for testing
				[Player2] = CFrame.new(math.sin(i), i, math.cos(i)),
				[Player3] = CFrame.new(0, 1, 2) * CFrame.Angles(0.5 * math.pi, 0, 0),
			}

			-- (for testing that the cutscene accounts for players leaving)
			if i < frameAtWhichPlayer4Disconnects then
				TestCFrames[i][Player4] = CFrame.lookAt(Vector3.new(i, -2 * i, 3 * i), Vector3.new(3 * i, 2 * i, -i))
			elseif i == frameAtWhichPlayer4Disconnects then
				SoccerDuels.disconnectPlayerFromAllMapInstances(Player4)
			end

			for Player, characterCFrame in TestCFrames[i] do
				Player.Character.HumanoidRootPart.CFrame = characterCFrame
			end

			SoccerDuels.addExtraSecondsForTesting(cutsceneSecondsPerFrame - maxError)
			SoccerDuels.mapTimerTick()
			Client1:MapTimerTick()

			if i == frameAtWhichPlayerScoresGoal then
				SoccerDuels.playerScoredGoal(Player1)
			end

			if i < frameAtWhichPlayerScoresGoal then
				assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay", i)
			else
				assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver", i)
			end
		end

		local j = 0
		for i, PlayerCFramesThisFrame in Client1:IterateEndOfMatchPlayerCFrames() do
			j += 1

			assert(i == j)
			assert(TestCFrames[j][Player1] == PlayerCFramesThisFrame[Player1])
			assert(TestCFrames[j][Player2] == PlayerCFramesThisFrame[Player2])
			assert(TestCFrames[j][Player3] == PlayerCFramesThisFrame[Player3])
			assert(TestCFrames[j][Player4] == PlayerCFramesThisFrame[Player4]) -- this should be nil for j >= 10 b/ Player4 disconnected
		end

		if not (j == totalNumFrames) then
			error(`{j} != {totalNumFrames}`)
		end

		SoccerDuels.destroyMapInstance(mapId)
		Client1:Destroy()
		Client2:Destroy()
		Client3:Destroy()
		Client4:Destroy()
	end)
end
