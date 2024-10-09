-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	it("Clients can read the name of the map they get connected to + their team index", function()
		SoccerDuels.disconnectAllPlayers()
		SoccerDuels.destroyAllMapInstances()
		SoccerDuels.resetTestingVariables()

		local Player1 = MockInstance.new("Player")
		local Player2 = MockInstance.new("Player")

		local Client1 = SoccerDuels.newClient(Player1)
		local Client2 = SoccerDuels.newClient(Player2)

		Client1:LoadPlayerDataAsync()
		Client2:LoadPlayerDataAsync()

		local mapId = SoccerDuels.newMapInstance("Stadium")

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 2)

		assert(Client1:GetConnectedMapName() == "Stadium")
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == 2)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == 2)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 1)

		assert(Client1:GetConnectedMapName() == "Stadium")
		assert(Client2:GetConnectedMapName() == "Stadium")
		assert(Client1:GetPlayerTeamIndex(Player1) == 2)
		assert(Client1:GetPlayerTeamIndex(Player2) == 1)
		assert(Client2:GetPlayerTeamIndex(Player1) == 2)
		assert(Client2:GetPlayerTeamIndex(Player2) == 1)

		SoccerDuels.disconnectPlayerFromAllMapInstances(Player1)

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == "Stadium")
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == 1)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == 1)

		SoccerDuels.destroyMapInstance(mapId)

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		Client1:Destroy()
		Client2:Destroy()
	end)
	it(
		"An event fires on the client whenever someone in their map scores a goal, assists a goal, or tackles someone",
		function()
			SoccerDuels.disconnectAllPlayers()
			SoccerDuels.destroyAllMapInstances()
			SoccerDuels.resetTestingVariables()

			local maxError = 0.010
			local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
			local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
			local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
			local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")

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

			local mapId1 = SoccerDuels.newMapInstance("Stadium")
			local mapId2 = SoccerDuels.newMapInstance("Map2")

			SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
			SoccerDuels.connectPlayerToMapInstance(Player2, mapId1, 2)
			SoccerDuels.connectPlayerToMapInstance(Player3, mapId2, 1)
			SoccerDuels.connectPlayerToMapInstance(Player4, mapId2, 2)

			local changeCount = 0
			local LastPlayer, lastTeamIndex, lastGoals, lastAssists, lastTackles
			local callback = function(...)
				changeCount += 1
				LastPlayer, lastTeamIndex, lastGoals, lastAssists, lastTackles = ...
			end

			SoccerDuels.playerScoredGoal(Player1) -- doesn't count while map is loading
			SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
			SoccerDuels.mapTimerTick()

			SoccerDuels.playerAssistedGoal(Player2) -- doesn't count during match countdown
			SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
			SoccerDuels.mapTimerTick()

			assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")

			SoccerDuels.playerTackledAnotherPlayer(Player2)
			SoccerDuels.playerScoredGoal(Player3) -- doesn't count (on a different map)
			SoccerDuels.playerAssistedGoal(Player4)

			local conn = Client1:OnPlayerLeaderstatsChangedConnect(callback)

			assert(changeCount == 2)
			if LastPlayer == Player1 then
				assert(lastTeamIndex == 1)
				assert(lastGoals == 0)
				assert(lastAssists == 0)
				assert(lastTackles == 0)
			else
				assert(LastPlayer == Player2)
				if not (lastTeamIndex == 2) then
					error(`{lastTeamIndex} != 2`)
				end
				assert(lastGoals == 0)
				assert(lastAssists == 0)
				assert(lastTackles == 1)
			end

			SoccerDuels.playerScoredGoal(Player1)

			assert(changeCount == 3)
			assert(LastPlayer == Player1)
			assert(lastTeamIndex == 1)
			assert(lastGoals == 1)
			assert(lastAssists == 0)
			assert(lastTackles == 0)

			SoccerDuels.playerAssistedGoal(Player2)

			assert(changeCount == 4)
			assert(LastPlayer == Player2)
			assert(lastTeamIndex == 2)
			assert(lastGoals == 0)
			assert(lastAssists == 1)
			assert(lastTackles == 1)

			conn:Disconnect()

			changeCount = 0
			LastPlayer, lastGoals, lastAssists, lastTackles = nil, nil, nil, nil

			SoccerDuels.playerAssistedGoal(Player1)
			SoccerDuels.playerTackledAnotherPlayer(Player2)
			SoccerDuels.playerTackledAnotherPlayer(Player3)
			SoccerDuels.playerScoredGoal(Player4)

			assert(changeCount == 0)

			conn = Client2:OnPlayerLeaderstatsChangedConnect(callback)

			assert(changeCount == 2)
			if LastPlayer == Player1 then
				assert(lastTeamIndex == 1)
				assert(lastGoals == 1)
				assert(lastAssists == 1)
				assert(lastTackles == 0)
			else
				assert(LastPlayer == Player2)
				assert(lastTeamIndex == 2)
				assert(lastGoals == 0)
				assert(lastAssists == 1)
				assert(lastTackles == 2)
			end

			SoccerDuels.disconnectPlayerFromAllMapInstances(Player1)

			assert(changeCount == 3)
			assert(LastPlayer == Player1)
			assert(lastTeamIndex == nil)
			assert(lastGoals == nil)
			assert(lastAssists == nil)
			assert(lastTackles == nil)

			SoccerDuels.destroyMapInstance(mapId1)

			assert(changeCount == 4)
			assert(LastPlayer == Player2)
			assert(lastTeamIndex == nil)
			assert(lastGoals == nil)
			assert(lastAssists == nil)
			assert(lastTackles == nil)

			mapId1 = SoccerDuels.newMapInstance("Stadium")
			SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 2)

			assert(changeCount == 4)

			SoccerDuels.connectPlayerToMapInstance(Player2, mapId1, 1)

			if not (changeCount == 6) then
				error(`{changeCount} != 6`)
			end
			assert(LastPlayer == Player1 or LastPlayer == Player2)
			assert(lastTeamIndex == if LastPlayer == Player2 then 1 else 2)
			assert(lastGoals == 0)
			assert(lastAssists == 0)
			assert(lastTackles == 0)

			conn:Disconnect()
			SoccerDuels.destroyMapInstance(mapId1)

			assert(changeCount == 6)

			SoccerDuels.destroyMapInstance(mapId2)
			Client1:Destroy()
			Client2:Destroy()
			Client3:Destroy()
			Client4:Destroy()
		end
	)
end
