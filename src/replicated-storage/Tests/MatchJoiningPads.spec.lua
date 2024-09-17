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
        --[[
		describe("Client:JoinPad()", function()
			local MockPlayer = MockInstance.new("Player")
			MockPlayer.Name = "Dave"

			local Client = SoccerDuels.newClient(MockPlayer)

			Client:JoinPad("Pad1")
		end)--]]
	end)
end
