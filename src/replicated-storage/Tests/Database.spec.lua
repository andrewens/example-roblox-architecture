local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("SoccerDuels database", function()
		describe("Client:LoadPlayerDataAsync()", function()
			it("Loads the user's saved data onto the client, returning a boolean representing if it was successful", function()
                local MockPlayer = MockInstance.new("Player")
                local Client = SoccerDuels.newClient(MockPlayer)

                assert(nil == Client:GetPlayerSaveData())

                local success = Client:LoadPlayerDataAsync() -- because this is in testing mode, it's not actually async here
                local PlayerSaveData = Client:GetPlayerSaveData()

                assert(typeof(success) == "boolean")
                assert(typeof(PlayerSaveData) == "table")

                -- default save data for new players
                assert(PlayerSaveData.Level == 0)
                assert(PlayerSaveData.WinStreak == 0)
                assert(typeof(PlayerSaveData.Settings) == "table")
			end)
		end)
	end)
end
