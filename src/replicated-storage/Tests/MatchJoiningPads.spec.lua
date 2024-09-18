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
		describe("Client:JoinMatchPadAsync()", function()
			it("Connects client to a match joining pad on the server", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				-- can't join matches until we're loaded
				s = pcall(Client.JoinMatchPadAsync, Client, "1v1 #1", 1)
				assert(not s)

				Client:LoadPlayerDataAsync()

				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				-- input validation
				s = pcall(Client.JoinMatchPadAsync, Client, "1v1 #1", "This isn't a team number")
				assert(not s)

				s = pcall(Client.JoinMatchPadAsync, Client, "This isn't a match pad name", 1)
				assert(not s)

				s = pcall(Client.JoinMatchPadAsync, Client, "1v1 #1", 3) -- only can pass 1 or 2 for teams
				assert(not s)

				-- getters / setters
				Client:JoinMatchPadAsync("1v1 #1", 1) -- not actually async when in testing mode on server

				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 1)

				Client:JoinMatchPadAsync("1v1 #1", 2)

				assert(Client:GetConnectedMatchPadName() == "1v1 #1")
				assert(Client:GetConnectedMatchPadTeam() == 2)

				Client:DisconnectFromMatchPadAsync()

				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				Client:DisconnectFromMatchPadAsync()

				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				Client:Destroy()
			end)
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

					Client:JoinMatchPadAsync("1v1 #1", 1)

					assert(changeCount == 2)
					assert(lastUIMode == "MatchJoiningPad")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					Client:JoinMatchPadAsync("1v1 #1", 2)

					assert(changeCount == 2)
					assert(lastUIMode == "MatchJoiningPad")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					Client:DisconnectFromMatchPadAsync()

					assert(changeCount == 3)
					assert(lastUIMode == "Lobby")
					assert(Client:GetUserInterfaceMode() == lastUIMode)

					conn:Disconnect()
					Client:JoinMatchPadAsync("1v1 #1", 2)

					assert(changeCount == 3)
					assert(lastUIMode == "Lobby")
					assert(Client:GetUserInterfaceMode() == "MatchJoiningPad")

					Client:Destroy()
				end
			)
			it(
				"If a player isn't standing on the pad, they get teleported to it when they connect; if they step off, they get disconnected",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.resetTestingVariables()

					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)

					Client:LoadPlayerDataAsync()

					local Pad1 = SoccerDuels.getExpectedAsset("1v1 #1 Pad1")
					local Pad2 = SoccerDuels.getExpectedAsset("1v1 #1 Pad2")
					local Char = MockPlayer.Character

					local padRadius = 0.5 * Pad1.Size.X -- assuming pad is a sphere
					local padRadiusSquared = padRadius * padRadius
					local offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					local offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) > padRadiusSquared)

					Client:JoinMatchPadAsync("1v1 #1", 2)

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) <= padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == "1v1 #1")
					assert(Client:GetConnectedMatchPadTeam() == 2)

					Client:JoinMatchPadAsync("1v1 #1", 1)

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(offset1:Dot(offset1) <= padRadiusSquared)
					assert(offset2:Dot(offset2) > padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == "1v1 #1")
					assert(Client:GetConnectedMatchPadTeam() == 1)

					local positionInPad2 = Pad2.Position + Vector3.new(padRadius - 0.1, 0, 0)

					Char:MoveTo(positionInPad2)
					Client:JoinMatchPadAsync("1v1 #1", 2)

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					if not (Char.HumanoidRootPart.Position:FuzzyEq(positionInPad2)) then -- don't teleport if we're already in the pad
						error(`{Char.HumanoidRootPart.Position} != {positionInPad2}`)
					end
					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) <= padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == "1v1 #1")
					assert(Client:GetConnectedMatchPadTeam() == 2)

					local dr = Pad2.Position - Pad1.Position
					local radiusPadding = SoccerDuels.getConstant("MatchJoiningPadRadiusPaddingStuds")
					local positionOutsideOfPads = dr.Unit * (padRadius + radiusPadding + 0.1) + Pad2.Position

					Char:MoveTo(positionOutsideOfPads)
					Client:DisconnectFromMatchJoiningPadIfCharacterSteppedOff()

					offset1 = Pad1.Position - Char.HumanoidRootPart.Position
					offset2 = Pad2.Position - Char.HumanoidRootPart.Position

					assert(Char.HumanoidRootPart.Position:FuzzyEq(positionOutsideOfPads))
					assert(offset1:Dot(offset1) > padRadiusSquared)
					assert(offset2:Dot(offset2) > padRadiusSquared)
					assert(Client:GetConnectedMatchPadName() == nil)
					assert(Client:GetConnectedMatchPadTeam() == 1)

					Client:Destroy()
				end
			)
			it(
				"If a player's character touches a match pad part, the client joins that match joining pad", function()
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

					Client:Destroy()
				end
			)
		end)
		describe("SoccerDuels.connectPlayerToMatchPad()", function()
			it("Forces a client to connect to that match pad", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				Client:LoadPlayerDataAsync()
				Client:JoinMatchPadAsync("1v1 #1", 1)

				SoccerDuels.connectPlayerToMatchPad(MockPlayer, "1v1 #2", 2)

				assert(Client:GetConnectedMatchPadName() == "1v1 #2")
				assert(Client:GetConnectedMatchPadTeam() == 2)

				SoccerDuels.disconnectPlayer(MockPlayer)

				assert(Client:GetConnectedMatchPadName() == nil)
				assert(Client:GetConnectedMatchPadTeam() == 1)

				--local s = pcall(Client.JoinMatchPadAsync, Client, "1v1 #1", 1)
				--assert(not s)

				Client:Destroy()
			end)
		end)
	end)
end
