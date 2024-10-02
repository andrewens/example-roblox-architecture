-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("Map voting", function()
		describe("Client:VoteForMap()", function()
			it(
				"Clients can vote for a map if they're connected to a MatchJoiningPad and it is in a 'MapVoting' state",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
					local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")
					local maxError = 0.010

					local TestMapVotes = {}
					local EmptyMapVotes = {} -- (just never set the values of this so it stays at 0)
					for mapEnum, mapName in SoccerDuels.iterateEnumsOfType("Map") do
						TestMapVotes[mapName] = 0
						EmptyMapVotes[mapName] = 0
					end

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					-- players can only vote if they're connected to a match joining pad in a 'MapVoting' state
					local s = pcall(Client1.VoteForMap, Client1, "Stadium")
					assert(not s)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
					Client1:VoteForMap("Stadium")

					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")

					Client1:VoteForMap("Stadium")
					Client2:VoteForMap("Stadium")

					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()
					Client1:VoteForMap("Stadium")
					Client2:VoteForMap("Stadium")
					TestMapVotes.Stadium = 2

					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					-- players can vote for nothing
					Client1:VoteForMap(nil)
					TestMapVotes.Stadium = 1

					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					-- players only get one vote
					Client2:VoteForMap("Map2") -- TODO will need to change this map name later
					TestMapVotes.Stadium = 0
					TestMapVotes.Map2 = 1

					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					-- if a player disconnects from the match joining pad, the votes all return to 0
					SoccerDuels.teleportPlayerToLobbySpawnLocation(Player2)
					TestMapVotes.Map2 = 0

					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					-- when a match pad ends the map voting state, all votes return to 0
					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)
					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()
					Client1:VoteForMap("Map2")
					Client2:VoteForMap("Stadium")
					TestMapVotes.Map2 = 1
					TestMapVotes.Stadium = 1

					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					SoccerDuels.addExtraSecondsForTesting(mapVotingDuration + maxError)
					SoccerDuels.matchPadTimerTick()
					TestMapVotes.Map2 = 0
					TestMapVotes.Stadium = 0

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableDeepEqual(TestMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #1")))
					assert(Utility.tableDeepEqual(EmptyMapVotes, SoccerDuels.getMatchPadMapVotes("1v1 #2")))

					Client1:Destroy()
					Client2:Destroy()
				end
			)
			it(
				"The player who voted last breaks ties, but you can't spam the same vote to maintain tie-breaker status",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
					local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")
					local maxError = 0.010

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					Client1:TeleportToMatchPadAsync("1v1 #1", 1)
					Client2:TeleportToMatchPadAsync("1v1 #1", 2)

					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == nil)

					Client1:VoteForMap("Stadium")

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == "Stadium")

					Client2:VoteForMap("Map2")

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == "Map2")

					Client1:VoteForMap("Map2")

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == "Map2")

					Client1:VoteForMap("Stadium")

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == "Stadium")

					Client2:VoteForMap("Map2") -- since Client2 already voted for Map2, this doesn't give them the tie-breaker status

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == "Stadium")

					SoccerDuels.addExtraSecondsForTesting(mapVotingDuration + maxError)
					SoccerDuels.matchPadTimerTick()

					assert(SoccerDuels.getMatchPadWinningMapVote("1v1 #1") == nil)

					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
		describe("Client:OnConnectedMatchPadVoteChangedConnect()", function()
			it(
				"Invokes callback whenever a player changes their vote in the match joining pad the client is connected to",
				function()
					local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
					local maxError = 0.010

					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")

					Client2:VoteForMap("Stadium")

					local changeCount = 0
					local LastPlayer, lastMapName
					local callback = function(...)
						changeCount += 1
						LastPlayer, lastMapName = ...
					end
					local conn = Client1:OnConnectedMatchPadVoteChangedConnect(callback)

					if not (changeCount == 1) then
						error(`{changeCount} != 1`)
					end
					assert(LastPlayer == Player2)
					assert(lastMapName == "Stadium")

					Client1:VoteForMap("Map2")

					assert(changeCount == 2)
					assert(LastPlayer == Player1)
					assert(lastMapName == "Map2")

					Client2:VoteForMap(nil)

					assert(changeCount == 3)
					assert(LastPlayer == Player2)
					assert(lastMapName == nil)

					conn:Disconnect()

					changeCount = 0
					LastPlayer, lastMapName = nil, nil

					Client2:VoteForMap("Map2")

					assert(changeCount == 0)

					conn = Client1:OnConnectedMatchPadVoteChangedConnect(callback)

					assert(changeCount == 2)
					assert(LastPlayer == Player1 or LastPlayer == Player2)
					assert(lastMapName == "Map2")

					Client1:VoteForMap("Map2") -- this isn't a different vote so it shouldn't invoke a callback

					assert(changeCount == 2)
					assert(LastPlayer == Player1 or LastPlayer == Player2)
					assert(lastMapName == "Map2")

					conn:Disconnect()
					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
	end)
end
