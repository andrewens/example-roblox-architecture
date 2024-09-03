local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("SoccerDuels.newClient()", function()
		it("Creates a new Client object, provided a Player Instance or mock Player", function()
			local MockPlayer = MockInstance.new("Player")
			local Client = SoccerDuels.newClient(MockPlayer)

			assert(typeof(Client) == "table")

			local s = pcall(SoccerDuels.newClient, nil)

			assert(not s)

			s = pcall(SoccerDuels.newClient, Instance.new("Part"))

			assert(not s)
		end)
		it("Clones UserInterface ScreenGuis into the Player's PlayerGui", function()
			local MockPlayer = MockInstance.new("Player")
			local Client = SoccerDuels.newClient(MockPlayer)

			assert(MockPlayer.PlayerGui.Windows) --> TODO this should use ExpectedAssets...?
		end)
	end)
end
