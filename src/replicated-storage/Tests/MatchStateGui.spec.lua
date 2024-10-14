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
	it("Client can read the timestamp when when the match state will change", function()
		SoccerDuels.disconnectAllPlayers()
		SoccerDuels.destroyAllMapInstances()
		SoccerDuels.resetTestingVariables()

		local maxError = 0.010
		local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
		local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
		local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
		local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
		local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")

		-- connect Players to map
		local Player1 = MockInstance.new("Player")
		local Player2 = MockInstance.new("Player")

		local Client1 = SoccerDuels.newClient(Player1)
		local Client2 = SoccerDuels.newClient(Player2)

		Client1:LoadPlayerDataAsync()
		Client2:LoadPlayerDataAsync()

		local mapId = SoccerDuels.newMapInstance("Stadium")
		local serverTimestamp = SoccerDuels.getUnixTimestampMilliseconds() + 1E3 * mapLoadingDuration

		assert(Client1:GetConnectedMapStateChangeTimestamp() == nil)
		assert(Client2:GetConnectedMapStateChangeTimestamp() == nil)

		-- 'LoadingMap'
		SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 2)
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 1)

		assert(Client1:GetUserInterfaceMode() == "LoadingMap")

		local client1Timestamp = Client1:GetConnectedMapStateChangeTimestamp()
		local client2Timestamp = Client2:GetConnectedMapStateChangeTimestamp()

		assert(client1Timestamp == client2Timestamp)
		assert(math.abs(serverTimestamp - client1Timestamp) < 1E3 * maxError)

		SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- 'MatchCountdown'
		assert(Client1:GetUserInterfaceMode() == "MatchCountdown")

		serverTimestamp = SoccerDuels.getUnixTimestampMilliseconds() + 1E3 * matchCountdownDuration
		client1Timestamp = Client1:GetConnectedMapStateChangeTimestamp()
		client2Timestamp = Client2:GetConnectedMapStateChangeTimestamp()

		assert(client1Timestamp == client2Timestamp)
		assert(math.abs(serverTimestamp - client1Timestamp) < 1E3 * maxError)

		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- 'MatchGameplay'
		assert(Client1:GetUserInterfaceMode() == "MatchGameplay")

		serverTimestamp = SoccerDuels.getUnixTimestampMilliseconds() + 1E3 * matchGameplayDuration
		client1Timestamp = Client1:GetConnectedMapStateChangeTimestamp()
		client2Timestamp = Client2:GetConnectedMapStateChangeTimestamp()

		assert(client1Timestamp == client2Timestamp)
		assert(math.abs(serverTimestamp - client1Timestamp) < 1E3 * maxError)

		SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- 'MatchOver'
		assert(Client1:GetUserInterfaceMode() == "MatchOver")

		serverTimestamp = SoccerDuels.getUnixTimestampMilliseconds() + 1E3 * matchOverDuration
		client1Timestamp = Client1:GetConnectedMapStateChangeTimestamp()
		client2Timestamp = Client2:GetConnectedMapStateChangeTimestamp()

		assert(client1Timestamp == client2Timestamp)
		assert(math.abs(serverTimestamp - client1Timestamp) < 1E3 * maxError)

		SoccerDuels.disconnectPlayer(Player2)
		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- 'GameOver'
		assert(Client1:GetUserInterfaceMode() == "GameOver")

		serverTimestamp = SoccerDuels.getUnixTimestampMilliseconds() + 1E3 * gameOverDuration
		client1Timestamp = Client1:GetConnectedMapStateChangeTimestamp()
		client2Timestamp = Client2:GetConnectedMapStateChangeTimestamp()

		assert(client2Timestamp == nil)
		assert(math.abs(serverTimestamp - client1Timestamp) < 1E3 * maxError)

		SoccerDuels.destroyMapInstance(mapId)

		-- no connected map
		assert(Client1:GetConnectedMapStateChangeTimestamp() == nil)

		Client1:Destroy()
		Client2:Destroy()
	end)
	it("An event fires on the client when someone in their map joins or leaves", function()
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

		local joinedCount, leftCount = 0, 0
		local LastPlayerThatJoined, LastPlayerThatLeft
		local callback1 = function(...)
			joinedCount += 1
			LastPlayerThatJoined = ...
		end
		local callback2 = function(...)
			leftCount += 1
			LastPlayerThatLeft = ...
		end

		local conn1 = Client1:OnPlayerJoinedConnectedMap(callback1)
		local conn2 = Client1:OnPlayerLeftConnectedMap(callback2)

		-- joined callback fires for players already in the map when connected
		if not (joinedCount == 2) then
			error(`{joinedCount} != 2`)
		end
		assert(LastPlayerThatJoined == Player1 or LastPlayerThatJoined == Player2)
		assert(leftCount == 0)
		assert(LastPlayerThatLeft == nil)

		-- left callback fires when another player disconnects from the map
		SoccerDuels.disconnectPlayerFromAllMapInstances(Player2)

		assert(joinedCount == 2)
		assert(LastPlayerThatJoined == Player1 or LastPlayerThatJoined == Player2)
		if not (leftCount == 1) then
			error(`{leftCount} != 1`)
		end
		assert(LastPlayerThatLeft == Player2)

		-- left callback fires when map instance is destroyed (for all players)
		SoccerDuels.destroyMapInstance(mapId1)

		assert(joinedCount == 2)
		assert(LastPlayerThatJoined == Player1 or LastPlayerThatJoined == Player2)
		assert(leftCount == 2)
		assert(LastPlayerThatLeft == Player1)

		-- joined callback fires for players already in the map when connected
		joinedCount, leftCount = 0, 0
		LastPlayerThatJoined, LastPlayerThatLeft = nil, nil

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId2, 1)

		if not (joinedCount == 3) then
			error(`{joinedCount} != 3`)
		end
		if
			not (LastPlayerThatJoined == Player1 or LastPlayerThatJoined == Player3 or LastPlayerThatJoined == Player4)
		then
			error(`{LastPlayerThatJoined} is not a Player in the map!`)
		end
		assert(leftCount == 0)
		assert(LastPlayerThatLeft == nil)

		-- joined callback fires when another player joins the map
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId2, 2)

		if not (joinedCount == 4) then
			error(`{joinedCount} != 4`)
		end
		assert(LastPlayerThatJoined == Player2)
		assert(leftCount == 0)
		assert(LastPlayerThatLeft == nil)

		-- left callback fires for all players when the client disconnects from the match
		SoccerDuels.disconnectPlayerFromAllMapInstances(Player1)

		if not (joinedCount == 4) then
			error(`{joinedCount} != 4`)
		end
		assert(LastPlayerThatJoined == Player2)
		if not (leftCount == 4) then
			error(`{leftCount} != 4`)
		end
		assert(
			LastPlayerThatLeft == Player1
				or LastPlayerThatLeft == Player2
				or LastPlayerThatLeft == Player3
				or LastPlayerThatLeft == Player4
		)

		-- callbacks don't fire after they get disconnected
		conn1:Disconnect()
		conn2:Disconnect()

		joinedCount, leftCount = 0, 0
		LastPlayerThatJoined, LastPlayerThatLeft = nil, nil

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId2, 1)
		SoccerDuels.disconnectPlayerFromAllMapInstances(Player3)
		SoccerDuels.destroyMapInstance(mapId2)

		assert(joinedCount == 0)
		assert(leftCount == 0)

		-- cleanup
		Client1:Destroy()
		Client2:Destroy()
		Client3:Destroy()
		Client4:Destroy()
	end)
	it("Client can bring up the leaderboard by pressing a key while they're connected to a map", function()
		SoccerDuels.disconnectAllPlayers()
		SoccerDuels.destroyAllMapInstances()
		SoccerDuels.resetTestingVariables()

		local defaultLeaderboardKey = SoccerDuels.getConstant("DefaultKeybinds", "Leaderboard")
		local notDefaultLeaderboardKey = if defaultLeaderboardKey == Enum.KeyCode.X
			then Enum.KeyCode.Y
			else Enum.KeyCode.X

		local LeaderboardKeyInputObject = MockInstance.new("InputObject", {
			KeyCode = defaultLeaderboardKey,
		})
		local NotLeaderboardInputObject = MockInstance.new("InputObject", {
			KeyCode = notDefaultLeaderboardKey,
		})

		local Player1 = MockInstance.new("Player")
		local Player2 = MockInstance.new("Player")

		local Client1 = SoccerDuels.newClient(Player1)
		local Client2 = SoccerDuels.newClient(Player2)

		Client1:LoadPlayerDataAsync()
		Client2:LoadPlayerDataAsync()

		-- client must be connected to a map to bring up leaderboard
		Client1:BeginInput(LeaderboardKeyInputObject)

		assert(Client1:GetVisibleModalName() == nil)

		-- any other modals go away when we join a map
		Client1:SetVisibleModalName("Settings")

		local mapId1 = SoccerDuels.newMapInstance("Stadium")

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId1, 2)

		assert(Client1:GetVisibleModalName() == nil)

		-- by holding leaderboard key, client can bring up the leaderboard
		Client1:BeginInput(LeaderboardKeyInputObject)
		assert(Client1:GetVisibleModalName() == "Leaderboard")

		Client1:EndInput(LeaderboardKeyInputObject)
		assert(Client1:GetVisibleModalName() == nil)

		-- tapping an input doesn't do anything here
		Client1:TapInput(LeaderboardKeyInputObject)
		assert(Client1:GetVisibleModalName() == nil)

		-- holding a different key doesn't work
		Client1:BeginInput(NotLeaderboardInputObject)
		assert(Client1:GetVisibleModalName() == nil)

		-- we can bring up the modal with SetVisibleModalName()
		Client1:SetVisibleModalName("Leaderboard")
		assert(Client1:GetVisibleModalName() == "Leaderboard")

		Client1:SetVisibleModalName(nil)
		assert(Client1:GetVisibleModalName() == nil)

		-- disconnecting from the map makes leaderboard go away
		Client1:SetVisibleModalName("Leaderboard")
		SoccerDuels.destroyMapInstance(mapId1)
		assert(Client1:GetVisibleModalName() == nil)

		-- client can't bring up leaderboard outside of a map
		Client1:BeginInput(LeaderboardKeyInputObject)
		assert(Client1:GetVisibleModalName() == nil)

		Client1:Destroy()
		Client2:Destroy()
	end)
end
