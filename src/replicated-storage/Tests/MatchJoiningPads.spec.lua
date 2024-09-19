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

					assert(changeCount == 2)
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
	end)
end
