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
		describe("Client:JoinMatchPadAsync() ", function()
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
            it("Client's UserInterfaceMode changes to 'MatchJoiningPad' when it is connected to a match joining pad", function()
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
            end)
		end)

		--[[
        What do the match pads need?

        * this stuff needs to get replicated to client
        * UI to display who is in it (callback + getter)
        * state for when it's ready to begin (is full)
        * state for ...
            WaitingForPlayers
            ChoosingMap
            JoiningMatch
        * state changed callback
        * teleport players to pad if they're not already on it
        * automatically disconnect player if they jump off the pad
        * connect players to pad when they touch it
        * connect players to pad from UI in lobby
        * get list of open duels
        * getter for chosen map
        * UI for picking maps
        * getter for player vs map choice + a callback for that
        * instant feedback from touching a pad on client
        ]]
	end)
end
