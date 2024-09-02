local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("SoccerDuels.newClient", function()
		it("Creates a new Client object, provided a Player Instance or mock Player", function()
			local MockPlayer = MockInstance.new("Player")
			local Client1 = SoccerDuels.newClient(MockPlayer)

			assert(typeof(Client1) == "table")

			local s = pcall(SoccerDuels.newClient, nil)

			assert(not s)

			s = pcall(SoccerDuels.newClient, Instance.new("Part"))

			assert(not s)
		end)
	end)
end
