-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(ReplicatedStorage.MockInstance)
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
		end)
		describe("SoccerDuels.getMatchPadState()", function()
			it(
				"State is 'WaitingForPlayers' if not enough players, otherwise 'Countdown' and then 'MapVoting', by timer",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local maxError = 0.001 -- seconds
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

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 2) -- attempt to join a full team lol
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.teleportPlayerToMatchPad(Player2, "1v1 #1", 1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.teleportPlayerToLobbySpawnLocation(Player1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))

					SoccerDuels.teleportPlayerToMatchPad(Player1, "1v1 #1", 2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.advanceMatchPadTimer(countdownDuration - maxError)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.advanceMatchPadTimer(2 * maxError)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player2 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.disconnectPlayer(Player2)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers")
					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.teleportPlayerToMatchPad(Player3, "1v1 #1", 1)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "Countdown")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.advanceMatchPadTimer(countdownDuration + maxError)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.advanceMatchPadTimer(mapVotingDuration - maxError)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "MapVoting")
					assert(Utility.tableShallowEqual(TeamPlayers[1], { Player3 }))
					assert(Utility.tableShallowEqual(TeamPlayers[2], { Player1 }))

					SoccerDuels.advanceMatchPadTimer(2 * maxError)
					TeamPlayers = SoccerDuels.getMatchPadTeamPlayers("1v1 #1")

					assert(SoccerDuels.getMatchPadState("1v1 #1") == "WaitingForPlayers") -- players are in the match now
					assert(Utility.tableShallowEqual(TeamPlayers[1], {}))
					assert(Utility.tableShallowEqual(TeamPlayers[2], {}))

					Client1:Destroy()
					Client2:Destroy()
					Client3:Destroy()
				end
			)
		end)
	end)
end
