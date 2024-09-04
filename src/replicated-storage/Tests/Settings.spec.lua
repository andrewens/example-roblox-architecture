local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("ClientSettings", function()
		describe("Client:GetSettings()", function()
			it("Returns a JSON-compatible array of setting objects", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)
				local ClientSettings = Client:GetSettings()

				assert(typeof(ClientSettings) == "table")

				for i, Setting in ClientSettings do
                    assert(typeof(Setting) == "table")
					assert(typeof(Setting.Name) == "string")
					assert(Setting.Value ~= nil)
				end
			end)
		end)
	end)
end
