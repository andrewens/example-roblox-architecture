-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("Match joining pads", function()
		it("The server initializes the pads in the map", function()
			SoccerDuels.disconnectAllPlayers()

			local Pads = SoccerDuels.getMatchJoiningPads()

			assert(typeof(Pads) == "table")
			assert(#Pads > 0)

			for i, PadData in Pads do
				assert(typeof(PadData.Name) == "string")
				assert(Utility.isInteger(PadData.MaxPlayersPerTeam))
				assert(typeof(PadData.Team1) == "table")
				assert(typeof(PadData.Team2) == "table")
			end
		end)
		describe("SoccerDuels.teleportPlayerToMatchPad()", function()
			it("Teleports a player's character to a match pad if they're in the lobby", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 1) -- this shouldn't do anything because client hasn't loaded yet
				Client:LoadPlayerDataAsync()

				local Pad1 = SoccerDuels.getExpectedAsset("1v1 #1 Pad1")
				local Pad2 = SoccerDuels.getExpectedAsset("1v1 #1 Pad2")
				local Char = MockPlayer.Character

				local radiusPadding = SoccerDuels.getConstant("MatchJoiningPadRadiusPaddingStuds")
				local padRadius = 0.5 * Pad1.Size.X + radiusPadding -- assuming pad is a sphere
				local padRadiusSquared = padRadius * padRadius
				local offset1 = Pad1.Position - Char.HumanoidRootPart.Position
				local offset2 = Pad2.Position - Char.HumanoidRootPart.Position

				assert(offset1:Dot(offset1) > padRadiusSquared)
				assert(offset2:Dot(offset2) > padRadiusSquared)
				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 1)

				offset1 = Pad1.Position - Char.HumanoidRootPart.Position
				offset2 = Pad2.Position - Char.HumanoidRootPart.Position

				assert(offset1:Dot(offset1) <= padRadiusSquared)
				assert(offset2:Dot(offset2) > padRadiusSquared)
				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 1)

				SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 2)

				offset1 = Pad1.Position - Char.HumanoidRootPart.Position
				offset2 = Pad2.Position - Char.HumanoidRootPart.Position

				assert(offset1:Dot(offset1) > padRadiusSquared)
				assert(offset2:Dot(offset2) <= padRadiusSquared)
				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 2)

				Client:Destroy()
			end)
		end)
		describe("SoccerDuels.getMatchPadState()", function()
			it(
				"State is 'WaitingForPlayers' if not enough players, otherwise 'Countdown' and then 'MapVoting', by timer",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local maxError = 0.010 -- seconds
					local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
					local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")
					local Player3 = MockInstance.new("Player")

					Player1.Name = "Player1"
					Player2.Name = "Player2"
					Player3.Name = "Player3"

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)
					local Client3 = SoccerDuels.newClient(Player3)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()
					Client3:LoadPlayerDataAsync()

					local TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2) -- attempt to join a full team lol
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Client1:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client2:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client3:GetMatchPadState("1v1 #1") == "Countdown")

					SoccerDuels.teleportPlayerToLobbySpawnLocation(Player1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Client1:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client2:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client3:GetMatchPadState("1v1 #1") == "Countdown")

					SoccerDuels.addExtraSecondsForTesting(countdownDuration - maxError)
					SoccerDuels.matchPadTimerTick()
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Client1:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client2:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client3:GetMatchPadState("1v1 #1") == "Countdown")

					SoccerDuels.addExtraSecondsForTesting(2 * maxError)
					SoccerDuels.matchPadTimerTick()
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Client1:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client2:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client3:GetMatchPadState("1v1 #1") == "MapVoting")

					SoccerDuels.disconnectPlayer(Player2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #1", 1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Client1:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client2:GetMatchPadState("1v1 #1") == "Countdown")
					assert(Client3:GetMatchPadState("1v1 #1") == "Countdown")

					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Client1:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client2:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client3:GetMatchPadState("1v1 #1") == "MapVoting")

					SoccerDuels.addExtraSecondsForTesting(mapVotingDuration - maxError)
					SoccerDuels.matchPadTimerTick()
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Client1:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client2:GetMatchPadState("1v1 #1") == "MapVoting")
					assert(Client3:GetMatchPadState("1v1 #1") == "MapVoting")

					SoccerDuels.addExtraSecondsForTesting(2 * maxError)
					SoccerDuels.matchPadTimerTick()
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))
					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers") -- players are in the match now
					assert(Client1:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client2:GetMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Client3:GetMatchPadState("1v1 #1") == "WaitingForPlayers")

					Client1:Destroy()
					Client2:Destroy()
					Client3:Destroy()
				end
			)
			it("Players' HumanoidRootParts are anchored if match pad state is 'MapVoting'", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local maxError = 0.010 -- seconds
				local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
				local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")

				Player1.Name = "Player1"
				Player2.Name = "Player2"

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()

				assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
				assert(Player1.Character.HumanoidRootPart.Anchored == false)
				assert(Player2.Character.HumanoidRootPart.Anchored == false)

				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 1)

				assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
				assert(Player1.Character.HumanoidRootPart.Anchored == false)
				assert(Player2.Character.HumanoidRootPart.Anchored == false)

				SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
				SoccerDuels.matchPadTimerTick()

				assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
				assert(Player1.Character.HumanoidRootPart.Anchored == true)
				assert(Player2.Character.HumanoidRootPart.Anchored == true)

				SoccerDuels.teleportPlayerToLobbySpawnLocation(Player1)

				assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
				assert(Player1.Character.HumanoidRootPart.Anchored == false)
				assert(Player2.Character.HumanoidRootPart.Anchored == false)

				Client1:Destroy()
				Client2:Destroy()
			end)
		end)
		describe("Client:TeleportToMatchPadAsync()", function()
			it(
				"Teleports a client's lobby character to a match pad and connects the client to the match pad",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)

					local s = pcall(Client.TeleportToMatchPadAsync, Client, "1v1 #1", 1) -- this should error because client hasn't loaded yet
					assert(not s)

					Client:LoadPlayerDataAsync()

					local Pad1 = SoccerDuels.getExpectedAsset("1v1 #1 Pad1")
					local Pad2 = SoccerDuels.getExpectedAsset("1v1 #1 Pad2")
					local Char = MockPlayer.Character

					local radiusPadding = SoccerDuels.getConstant("MatchJoiningPadRadiusPaddingStuds")
					local padRadius = 0.5 * Pad1.Size.X + radiusPadding -- assuming pad is a sphere
					local padRadiusSquared = padRadius * padRadius
					local offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					local offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) > padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == nil)
					assert(Client:GetConnectedMatchPadTeam() == 1)

					Client:TeleportToMatchPadAsync("1v1 #1", 1)

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) <= padRadiusSquared)
					assert(offset2:Dot(offset2) > padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == "1v1 #1")
					assert(Client:GetConnectedMatchPadTeam() == 1)

					Client:TeleportToMatchPadAsync("1v1 #1", 2)

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) <= padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == "1v1 #1")
					assert(Client:GetConnectedMatchPadTeam() == 2)

					Client:Destroy()
				end
			)
			it("Players can't join a match pad team that is full", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")
				local Player3 = MockInstance.new("Player")
				local Player4 = MockInstance.new("Player")

				Player1.Name = "PlayerA"
				Player2.Name = "PlayerB"
				Player3.Name = "PlayerC"
				Player4.Name = "PlayerD"

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)
				local Client3 = SoccerDuels.newClient(Player3)
				local Client4 = SoccerDuels.newClient(Player4)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()
				Client3:LoadPlayerDataAsync()
				Client4:LoadPlayerDataAsync()

				Client1:TeleportToMatchPadAsync("1v1 #1", 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player1) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player1) == 2)
				assert(Client1:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client1:GetConnectedMatchPadTeam() == 2)

				Client2:TeleportToMatchPadAsync("1v1 #1", 2) -- can't join because there's one max player

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player2) == nil)
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player2) == 1)
				assert(Client2:GetConnectedMatchPadName() == nil)
				assert(Client2:GetConnectedMatchPadTeam() == 1)

				SoccerDuels.disconnectPlayer(Player1) -- leave method #1 -- disconnected
				Client2:TeleportToMatchPadAsync("1v1 #1", 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player2) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player2) == 2)
				assert(Client2:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client2:GetConnectedMatchPadTeam() == 2)

				Client3:TeleportToMatchPadAsync("1v1 #1", 2) -- can't join because there's one max player

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player2) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player2) == 2)
				assert(Client2:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client2:GetConnectedMatchPadTeam() == 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player3) == nil)
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player3) == 1)
				assert(Client3:GetConnectedMatchPadName() == nil)
				assert(Client3:GetConnectedMatchPadTeam() == 1)

				Player2.Character.HumanoidRootPart.Position = Vector3.new(1E5, 1E5, 1E5) -- leave method #2 -- step off the pad
				Client2:DisconnectFromMatchJoiningPadIfCharacterSteppedOffAsync()
				Client3:TeleportToMatchPadAsync("1v1 #1", 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player2) == nil)
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player2) == 1)
				assert(Client2:GetConnectedMatchPadName() == nil)
				assert(Client2:GetConnectedMatchPadTeam() == 1)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player3) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player3) == 2)
				assert(Client3:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client3:GetConnectedMatchPadTeam() == 2)

				SoccerDuels.teleportPlayerToMatchPad(Player4, "1v1 #1", 2) -- can't join because there's one max player

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player3) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player3) == 2)
				assert(Client3:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client3:GetConnectedMatchPadTeam() == 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player4) == nil)
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player4) == 1)
				assert(Client4:GetConnectedMatchPadName() == nil)
				assert(Client4:GetConnectedMatchPadTeam() == 1)

				SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #2", 2) -- leave method #3 -- server teleports you to different pad
				SoccerDuels.teleportPlayerToMatchPad(Player4, "1v1 #1", 2) -- can't join because there's one max player

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player3) == "1v1 #2")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player3) == 2)
				assert(Client3:GetConnectedMatchPadName() == "1v1 #2")
				assert(Client3:GetConnectedMatchPadTeam() == 2)

				assert(SoccerDuels.getPlayerConnectedMatchPadName(Player4) == "1v1 #1")
				assert(SoccerDuels.getPlayerConnectedMatchPadTeam(Player4) == 2)
				assert(Client4:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client4:GetConnectedMatchPadTeam() == 2)

				Client1:Destroy()
				Client2:Destroy()
				Client3:Destroy()
				Client4:Destroy()
			end)
		end)
		describe("Client:LobbyCharacterTouchedPart()", function()
			it("If a player's character touches a match pad part, the client joins that match joining pad", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				Client:LoadPlayerDataAsync()

				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				local Pad1 = SoccerDuels.getExpectedAsset("1v1 #1 Pad1")
				local Pad2 = SoccerDuels.getExpectedAsset("1v1 #1 Pad2")

				Client:LobbyCharacterTouchedPart(Pad1)

				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 1)

				Client:LobbyCharacterTouchedPart(Pad2)
				Client:LobbyCharacterTouchedPart(Pad2) -- touching the same part twice shouldn't change what the player is connected to

				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 2)

				local Char = MockPlayer.Character
				local dr = Pad2.Position - Pad1.Position
				local radiusPadding = SoccerDuels.getConstant("MatchJoiningPadRadiusPaddingStuds")
				local padRadius = 0.5 * Pad1.Size.X + radiusPadding -- assuming pad is a sphere
				local padRadiusSquared = padRadius * padRadius
				local positionOutsideOfPads = dr.Unit * (padRadius + 0.1) + Pad2.Position

				Char:MoveTo(positionOutsideOfPads)
				Client:DisconnectFromMatchJoiningPadIfCharacterSteppedOffAsync()

				local offset1 = Pad1.Position - Char.HumanoidRootPart.Position
				local offset2 = Pad2.Position - Char.HumanoidRootPart.Position

				assert(Char.HumanoidRootPart.Position:FuzzyEq(positionOutsideOfPads))
				assert(offset1:Dot(offset1) > padRadiusSquared)
				assert(offset2:Dot(offset2) > padRadiusSquared)
				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				Client:Destroy()
			end)
			it("Fires an event when a character touches a match pad part", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				Client:LoadPlayerDataAsync()

				local Pad1 = SoccerDuels.getExpectedAsset("1v1 #1 Pad1")
				local Pad2 = SoccerDuels.getExpectedAsset("1v1 #1 Pad2")

				Client:LobbyCharacterTouchedPart(Pad2)

				local touchCount = 0
				local lastTouchedMatchPadName, lastTeamIndex
				local conn = Client:OnLobbyCharacterTouchedMatchPadConnect(function(...)
					touchCount += 1
					lastTouchedMatchPadName, lastTeamIndex = ...
				end)

				assert(touchCount == 0) -- doesn't count any currently touched parts

				Client:LobbyCharacterTouchedPart(Pad1)

				assert(touchCount == 1)
				assert(lastTouchedMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 1)

				Client:LobbyCharacterTouchedPart(Pad2)

				assert(touchCount == 2)
				assert(lastTouchedMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 2)

				SoccerDuels.teleportPlayerToLobbySpawnLocation(MockPlayer)

				assert(touchCount == 2)
				assert(lastTouchedMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 2)

				conn:Disconnect()
				Client:LobbyCharacterTouchedPart(Pad1)

				assert(touchCount == 2)
				assert(lastTouchedMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 2)

				Client:Destroy()
			end)
		end)
		describe("Client:OnUserInterfaceModeChangedConnect()", function()
			it(
				"Client's UserInterfaceMode changes to 'MatchJoiningPad' when it is connected to a match joining pad",
				function()
					SoccerDuels.disconnectAllPlayers()

					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)
					Client:LoadPlayerDataAsync()

					local changeCount = 0
					local lastUIMode
					local conn = Client:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
						changeCount += 1
						lastUIMode = userInterfaceMode
					end)

					assert(changeCount == 1)
					assert(lastUIMode == "Lobby")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 1)

					assert(changeCount == 2)
					assert(lastUIMode == "MatchJoiningPad")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 2)

					if not (changeCount == 2) then
						error(`{changeCount} != 2`)
					end
					assert(lastUIMode == "MatchJoiningPad")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					MockPlayer.Character.HumanoidRootPart.Position = Vector3.new(1E5, 1E5, 1E5)
					Client:DisconnectFromMatchJoiningPadIfCharacterSteppedOffAsync()

					assert(changeCount == 3)
					assert(lastUIMode == "Lobby")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					conn:Disconnect()
					SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 2)

					assert(changeCount == 3)
					assert(lastUIMode == "Lobby")
					assert(Client:GetUserInterfaceMode() == "MatchJoiningPad")

					Client:Destroy()
				end
			)
			it(
				"Client's ModalState gets set to nil when UserInterfaceMode changes from Lobby to MatchJoiningPads",
				function()
					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)

					assert(Client:GetUserInterfaceMode() == "None")
					assert(Client:GetVisibleModalName() == nil)

					Client:LoadPlayerDataAsync()
					Client:SetVisibleModalName("Settings")

					assert(Client:GetUserInterfaceMode() == "Lobby")
					assert(Client:GetVisibleModalName() == "Settings")

					SoccerDuels.teleportPlayerToMatchPad(MockPlayer, "1v1 #1", 1)

					assert(Client:GetUserInterfaceMode() == "MatchJoiningPad")
					assert(Client:GetVisibleModalName() == nil)

					Client:Destroy()
				end
			)
			it(
				"Client's UserInterfaceMode changes to 'MapVoting' when the client's match joining pad state is set to 'MapVoting'",
				function()
					local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
					local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")
					local maxError = 0.010

					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					assert(Client1:GetUserInterfaceMode() == "Lobby")
					assert(Client2:GetUserInterfaceMode() == "Lobby")

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

					assert(Client1:GetUserInterfaceMode() == "MatchJoiningPad")
					assert(Client2:GetUserInterfaceMode() == "MatchJoiningPad")

					SoccerDuels.addExtraSecondsForTesting(countdownDuration - maxError)
					SoccerDuels.matchPadTimerTick()

					assert(Client1:GetUserInterfaceMode() == "MatchJoiningPad")
					assert(Client2:GetUserInterfaceMode() == "MatchJoiningPad")

					SoccerDuels.addExtraSecondsForTesting(2 * maxError)
					SoccerDuels.matchPadTimerTick()

					assert(Client1:GetUserInterfaceMode() == "MapVoting")
					assert(Client2:GetUserInterfaceMode() == "MapVoting")

					SoccerDuels.teleportPlayerToLobbySpawnLocation(Player2)

					assert(Client1:GetUserInterfaceMode() == "MatchJoiningPad")
					assert(Client2:GetUserInterfaceMode() == "Lobby")

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)
					SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
					SoccerDuels.matchPadTimerTick()

					assert(Client1:GetUserInterfaceMode() == "MapVoting")
					assert(Client2:GetUserInterfaceMode() == "MapVoting")

					SoccerDuels.addExtraSecondsForTesting(mapVotingDuration - maxError)
					SoccerDuels.matchPadTimerTick()

					assert(Client1:GetUserInterfaceMode() == "MapVoting")
					assert(Client2:GetUserInterfaceMode() == "MapVoting")

					Client1:VoteForMap("Stadium")
					SoccerDuels.addExtraSecondsForTesting(2 * maxError)
					SoccerDuels.matchPadTimerTick()

					assert(Client1:GetUserInterfaceMode() == "Lobby") -- TODO
					assert(Client2:GetUserInterfaceMode() == "Lobby")

					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
		describe("Client:OnPlayerMatchPadChangedConnect()", function()
			it("Invokes a callback every time a player changes which match pad they're connected to", function()
				local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
				local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")
				local maxError = 0.001

				SoccerDuels.disconnectAllPlayers()

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")
				local Player3 = MockInstance.new("Player")

				Player1.Name = "Rigby"
				Player2.Name = "Mordecai"
				Player3.Name = "My Mom"

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)
				local Client3 = SoccerDuels.newClient(Player3)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()

				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #2", 1)

				-- callback is immediately invoked when connected (if there are players to fire the event for)
				local changeCount = 0
				local LastPlayer, lastMatchPadName, lastTeamIndex, conn
				local function callback(Player, matchPadName, teamIndex)
					changeCount += 1
					LastPlayer = Player
					lastMatchPadName = matchPadName
					lastTeamIndex = teamIndex
				end

				conn = Client2:OnPlayerMatchPadChangedConnect(callback)

				assert(changeCount == 2)

				if LastPlayer == Player1 then
					assert(lastMatchPadName == "1v1 #1")
					assert(lastTeamIndex == 2)
				elseif LastPlayer == Player2 then
					assert(lastMatchPadName == "1v1 #2")
					assert(lastTeamIndex == 1)
				else
					error(`{LastPlayer} is not a Player!`)
				end

				conn:Disconnect()

				-- callback is only invoked after client has loaded
				changeCount = 0
				LastPlayer, lastMatchPadName, lastTeamIndex = nil, nil, nil
				conn = Client3:OnPlayerMatchPadChangedConnect(callback)

				assert(changeCount == 0)

				Client3:LoadPlayerDataAsync()

				if not (changeCount == 2) then
					error(`{changeCount} != 2`)
				end

				if LastPlayer == Player1 then
					assert(lastMatchPadName == "1v1 #1")
					assert(lastTeamIndex == 2)
				elseif LastPlayer == Player2 then
					assert(lastMatchPadName == "1v1 #2")
					assert(lastTeamIndex == 1)
				else
					error(`{LastPlayer} is not a Player!`)
				end

				-- callback is invoked when a player's match pad changes
				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 1)

				assert(changeCount == 3)
				assert(LastPlayer == Player2)
				assert(lastMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 1)

				-- callback is invoked when a player disconnects from a match pad
				SoccerDuels.teleportPlayerToLobbySpawnLocation(Player1)

				assert(changeCount == 4)
				assert(LastPlayer == Player1)
				assert(lastMatchPadName == nil)
				assert(lastTeamIndex == 1)

				-- callback is invoked when player's team index changes
				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

				assert(changeCount == 5)
				assert(LastPlayer == Player2)
				assert(lastMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 2)

				-- callback is invoked when a player disconnects
				SoccerDuels.disconnectPlayer(Player2)

				assert(changeCount == 6)
				assert(LastPlayer == Player2)
				assert(lastMatchPadName == nil)
				assert(lastTeamIndex == 1)

				-- callback is not invoked when a player tries to join a team that's full
				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
				SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #1", 1)

				if not (changeCount == 7) then
					error(`{changeCount} != 7`)
				end
				assert(LastPlayer == Player1)
				assert(lastMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 1)

				-- callback is not invoked after it's disconnected
				conn:Disconnect()
				SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #1", 2)

				assert(changeCount == 7)
				assert(LastPlayer == Player1)
				assert(lastMatchPadName == "1v1 #1")
				assert(lastTeamIndex == 1)

				-- callback is invoked when players actually join the match
				changeCount = 0
				LastPlayer, lastMatchPadName, lastTeamIndex = nil, nil, nil
				conn = Client3:OnPlayerMatchPadChangedConnect(callback)

				assert(changeCount == 2)

				SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
				SoccerDuels.matchPadTimerTick()

				SoccerDuels.addExtraSecondsForTesting(mapVotingDuration + maxError)
				SoccerDuels.matchPadTimerTick()

				if not (changeCount == 4) then
					error(`{changeCount} != 4`)
				end
				assert(LastPlayer == Player1 or LastPlayer == Player3)
				assert(lastMatchPadName == nil)
				assert(lastTeamIndex == 1)

				conn:Disconnect()
				Client1:Destroy()
				Client2:Destroy()
				Client3:Destroy()
			end)
		end)
		describe("Client:OnPlayerMatchPadStateChangedConnect()", function()
			it("Invokes a callback whenever the player's connected match pad changes its state", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local countdownDuration = SoccerDuels.getConstant("MatchJoiningPadCountdownDurationSeconds")
				local mapVotingDuration = SoccerDuels.getConstant("MatchJoiningPadMapVotingDurationSeconds")

				local countdownDurationMilliseconds = countdownDuration * 1E3
				local mapVotingDurationMilliseconds = mapVotingDuration * 1E3

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")
				local Player3 = MockInstance.new("Player")

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)
				local Client3 = SoccerDuels.newClient(Player3)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()
				Client3:LoadPlayerDataAsync()

				local changeCount = 0
				local lastMatchStateName, lastStateEndTimestamp
				local callback = function(...)
					changeCount += 1
					lastMatchStateName, lastStateEndTimestamp = ...
				end

				local conn = Client1:OnPlayerMatchPadStateChangedConnect(callback)
				assert(changeCount == 0)

				conn:Disconnect()
				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
				conn = Client1:OnPlayerMatchPadStateChangedConnect(callback)

				assert(changeCount == 1)
				assert(lastMatchStateName == "WaitingForPlayers")
				assert(lastStateEndTimestamp == nil)

				SoccerDuels.teleportPlayerToLobbySpawnLocation(Player1)

				assert(changeCount == 2)
				assert(lastMatchStateName == nil)
				assert(lastStateEndTimestamp == nil)

				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)
				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #2", 1) -- other match pads shouldn't trigger our events
				SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #2", 2)

				if not (changeCount == 3) then
					error(`{changeCount} != 3`)
				end
				assert(lastMatchStateName == "WaitingForPlayers")
				assert(lastStateEndTimestamp == nil)

				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

				local now = SoccerDuels.getUnixTimestampMilliseconds()
				local maxError = 0.010
				local maxErrorMilliseconds = maxError * 1E3

				assert(changeCount == 4)
				assert(lastMatchStateName == "Countdown")
				if
					not (
						math.abs(lastStateEndTimestamp - (now + countdownDurationMilliseconds)) <= maxErrorMilliseconds
					)
				then
					error(
						`{math.abs(lastStateEndTimestamp - (now + countdownDurationMilliseconds))} > {maxErrorMilliseconds}`
					)
				end

				SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
				now = SoccerDuels.getUnixTimestampMilliseconds()
				SoccerDuels.matchPadTimerTick()

				assert(changeCount == 5)
				assert(lastMatchStateName == "MapVoting")
				if
					not (
						math.abs(lastStateEndTimestamp - (now + mapVotingDurationMilliseconds))
						<= 2 * maxErrorMilliseconds
					)
				then
					error(
						`{math.abs(lastStateEndTimestamp - (now + mapVotingDurationMilliseconds))} > {2 * maxErrorMilliseconds}`
					)
				end

				SoccerDuels.teleportPlayerToLobbySpawnLocation(Player2)

				assert(changeCount == 6)
				assert(lastMatchStateName == "WaitingForPlayers")
				assert(lastStateEndTimestamp == nil)

				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

				assert(changeCount == 7)
				assert(lastMatchStateName == "Countdown")
				assert(typeof(lastStateEndTimestamp) == "number")

				SoccerDuels.addExtraSecondsForTesting(countdownDuration + maxError)
				SoccerDuels.matchPadTimerTick()

				assert(changeCount == 8)
				assert(lastMatchStateName == "MapVoting")
				assert(typeof(lastStateEndTimestamp) == "number")

				SoccerDuels.addExtraSecondsForTesting(mapVotingDuration + maxError)
				SoccerDuels.matchPadTimerTick()

				assert(changeCount == 9)
				assert(lastMatchStateName == nil)
				assert(lastStateEndTimestamp == nil)

				SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2)

				assert(changeCount == 9)
				assert(lastMatchStateName == nil)
				assert(lastStateEndTimestamp == nil)

				conn:Disconnect()
				SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 1)

				assert(changeCount == 9)
				assert(lastMatchStateName == nil)
				assert(lastStateEndTimestamp == nil)

				Client1:Destroy()
				Client2:Destroy()
				Client3:Destroy()
			end)
		end)
	end)
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
