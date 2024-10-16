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
			assert(SoccerDuels.getMapInstanceState(mapId2) == "MatchGameplay")

			SoccerDuels.playerTackledAnotherPlayer(Player2)
			SoccerDuels.playerAssistedGoal(Player4)
			SoccerDuels.playerScoredGoal(Player3) -- doesn't count (on a different map)

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

			SoccerDuels.playerAssistedGoal(Player2)

			assert(changeCount == 3)
			assert(LastPlayer == Player2)
			assert(lastTeamIndex == 2)
			assert(lastGoals == 0)
			assert(lastAssists == 1)
			assert(lastTackles == 1)

			SoccerDuels.playerScoredGoal(Player1)

			assert(changeCount == 4)
			assert(LastPlayer == Player1)
			assert(lastTeamIndex == 1)
			assert(lastGoals == 1)
			assert(lastAssists == 0)
			assert(lastTackles == 0)

			SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
			SoccerDuels.mapTimerTick()
			SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
			SoccerDuels.mapTimerTick()

			assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
			assert(SoccerDuels.getMapInstanceState(mapId2) == "MatchGameplay")

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
				if not (lastGoals == 1) then
					error(`{lastGoals} != 1`)
				end
				assert(lastAssists == 1)
				assert(lastTackles == 0)
			else
				assert(LastPlayer == Player2)
				assert(lastTeamIndex == 2)
				if not (lastGoals == 0) then
					error(`{lastGoals} != 0`)
				end
				if not (lastAssists == 1) then
					error(`{lastAssists} != 1`)
				end
				if not (lastTackles == 2) then
					error(`{lastTackles} != 2`)
				end
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
	it("An event fires on the client when a team's score (total number of goals) changes", function()
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

		assert(Client1:GetTeamScore(1) == 0)
		assert(Client1:GetTeamScore(2) == 0)

		local mapId1 = SoccerDuels.newMapInstance("Stadium")

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId1, 2)
		SoccerDuels.connectPlayerToMapInstance(Player3, mapId1, 1)
		SoccerDuels.connectPlayerToMapInstance(Player4, mapId1, 2)

		local changeCount = 0
		local team1Score, team2Score
		local callback = function(...)
			changeCount += 1
			team1Score, team2Score = ...
		end

		-- players cannot score during map loading or match countdown
		SoccerDuels.playerScoredGoal(Player1)
		SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
		SoccerDuels.mapTimerTick()

		assert(Client1:GetWinningTeamIndex() == nil)
		assert(Client1:GetTeamScore(1) == 0)
		assert(Client1:GetTeamScore(2) == 0)
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchCountdown")

		SoccerDuels.playerScoredGoal(Player2)
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- callback is invoked with current score upon connecting
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		if not (Client1:GetWinningTeamIndex() == nil) then
			error(`{Client1:GetWinningTeamIndex()} != nil`)
		end
		assert(Client1:GetTeamScore(1) == 0)
		assert(Client1:GetTeamScore(2) == 0)

		SoccerDuels.playerTackledAnotherPlayer(Player2)
		SoccerDuels.playerAssistedGoal(Player1)
		SoccerDuels.playerScoredGoal(Player3)

		local conn = Client1:OnConnectedMapScoreChanged(callback)

		assert(changeCount == 1)
		assert(team1Score == 1)
		assert(team2Score == 0)
		assert(Client1:GetWinningTeamIndex() == 1)
		assert(Client1:GetTeamScore(1) == 1)
		assert(Client1:GetTeamScore(2) == 0)

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- callback is invoked every time the score changes
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerScoredGoal(Player2)

		assert(changeCount == 2)
		assert(team1Score == 1)
		assert(team2Score == 1)
		assert(Client1:GetWinningTeamIndex() == nil) -- nil for ties
		assert(Client1:GetTeamScore(1) == 1)
		assert(Client1:GetTeamScore(2) == 1)

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerScoredGoal(Player3)

		assert(changeCount == 3)
		assert(team1Score == 2)
		assert(team2Score == 1)
		assert(Client1:GetWinningTeamIndex() == 1)
		assert(Client1:GetTeamScore(1) == 2)
		assert(Client1:GetTeamScore(2) == 1)

		-- if a player disconnects, the goals they scored still count
		SoccerDuels.disconnectPlayer(Player3)

		if not (changeCount == 3) then
			error(`{changeCount} != 3`)
		end
		assert(team1Score == 2)
		assert(team2Score == 1)
		assert(Client1:GetWinningTeamIndex() == 1)
		assert(Client1:GetTeamScore(1) == 2)
		assert(Client1:GetTeamScore(2) == 1)

		-- players cannot score during match over
		if not (SoccerDuels.getMapInstanceState(mapId1) == "MatchOver") then
			error(`{SoccerDuels.getMapInstanceState(mapId1)} != "MatchOver"!`)
		end
		SoccerDuels.playerScoredGoal(Player2)

		assert(changeCount == 3)
		assert(Client1:GetWinningTeamIndex() == 1)
		assert(Client1:GetTeamScore(1) == 2)
		assert(Client1:GetTeamScore(2) == 1)

		-- callback is not invoked after we call disconnect
		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		changeCount = 0
		team1Score, team2Score = 0, 0
		conn:Disconnect()

		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerScoredGoal(Player4)

		assert(changeCount == 0)
		assert(team1Score == 0)
		assert(team2Score == 0)
		assert(Client1:GetWinningTeamIndex() == nil)
		assert(Client1:GetTeamScore(1) == 2)
		assert(Client1:GetTeamScore(2) == 2)

		SoccerDuels.destroyMapInstance(mapId1)

		assert(changeCount == 0)
		assert(Client1:GetTeamScore(1) == 0)
		assert(Client1:GetTeamScore(2) == 0)
		assert(Client1:GetWinningTeamIndex() == nil)

		Client1:Destroy()
		Client2:Destroy()
		Client3:Destroy()
		Client4:Destroy()
	end)
	it("The MVP of a game is whoever had the most goals", function()
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

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
		SoccerDuels.connectPlayerToMapInstance(Player2, mapId1, 2)
		SoccerDuels.connectPlayerToMapInstance(Player3, mapId1, 1)
		SoccerDuels.connectPlayerToMapInstance(Player4, mapId1, 2)

		SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- round 1: Player2 scores, Player4 assists
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerAssistedGoal(Player4)
		SoccerDuels.playerScoredGoal(Player2)

		assert(Client1:GetPlayerWhoScoredLastGoal() == Player2)
		assert(Client1:GetTeamMVP(1) == nil)
		assert(Client1:GetTeamMVP(2) == Player2) -- MVP is Player2

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- round 2: Player4 scores, Player2 assists
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerAssistedGoal(Player2)
		SoccerDuels.playerScoredGoal(Player4)

		assert(Client1:GetPlayerWhoScoredLastGoal() == Player4)
		assert(Client1:GetTeamMVP(1) == nil)
		assert(Client1:GetTeamMVP(2) == nil) -- MVP is nil because they're tied

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- round 3: Player1 scores, Player4 tackles
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerTackledAnotherPlayer(Player4)
		SoccerDuels.playerScoredGoal(Player1)

		assert(Client1:GetPlayerWhoScoredLastGoal() == Player1)
		assert(Client1:GetTeamMVP(1) == Player1)
		assert(Client1:GetTeamMVP(2) == Player4) -- Player4 is MVP because of the tackle

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- round 4: Player3 scores, Player1 assists
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerAssistedGoal(Player1)
		SoccerDuels.playerScoredGoal(Player3)

		assert(Client1:GetPlayerWhoScoredLastGoal() == Player3)
		assert(Client1:GetPlayerLeaderstat(Player1, "Assists") == 1)
		assert(Client1:GetPlayerLeaderstat(Player1, "Goals") == 1)
		assert(Client1:GetPlayerLeaderstat(Player3, "Assists") == 0)
		assert(Client1:GetPlayerLeaderstat(Player3, "Goals") == 1)
		if not (Client1:GetTeamMVP(1) == Player1) then -- Player1 is still MVP because assist + goal > just a goal
			error(`{Client1:GetTeamMVP(1)} != {Player1}`)
		end
		assert(Client1:GetTeamMVP(2) == Player4)

		SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
		SoccerDuels.mapTimerTick()
		SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
		SoccerDuels.mapTimerTick()

		-- round 5: Player3 scores, Player1 assists
		assert(SoccerDuels.getMapInstanceState(mapId1) == "MatchGameplay")
		SoccerDuels.playerAssistedGoal(Player1)
		SoccerDuels.playerScoredGoal(Player3)

		assert(Client1:GetPlayerWhoScoredLastGoal() == Player3)
		assert(Client1:GetTeamMVP(1) == Player3) -- Player3 is now MVP because they have two goals
		assert(Client1:GetTeamMVP(2) == Player4)

		-- cleanup
		SoccerDuels.destroyMapInstance(mapId1)
		Client1:Destroy()
		Client2:Destroy()
		Client3:Destroy()
		Client4:Destroy()
	end)
end
