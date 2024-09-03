local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("MenuButtons", function()
		describe("SoccerDuelsClient:ToggleModalVisibility()", function()
			it(
				"Makes a modal visible if it isn't currently, and makes a modal invisible if it is currently visible",
				function()
					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)

					assert(nil == Client:GetVisibleModalName()) --> TODO can test for modal popup when player joins game

					Client:ToggleModalVisibility("Settings")

					assert("Settings" == Client:GetVisibleModalName())

					Client:ToggleModalVisibility("Settings")

					assert(nil == Client:GetVisibleModalName())
				end
			)
			it("Throws an error if you pass an invalid modal name", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				local s = pcall(Client.ToggleModalVisibility, Client, "ThisIsn'tAModalName")

				assert(not s)

				s = pcall(Client.ToggleModalVisibility, Client, nil)

				assert(not s)
			end)
		end)
        describe("SoccerDuelsClient:OnVisibleModalChangedConnect()", function()
            it("Connects a callback to fire every time the visible modal changes", function()
                local MockPlayer = MockInstance.new("Player")
                local Client = SoccerDuels.newClient(MockPlayer)

                local changeCount = 0
                local lastModalName
                local conn = Client:OnVisibleModalChangedConnect(function(visibleModalName)
                    changeCount += 1
                    lastModalName = visibleModalName
                end)

                assert(1 == changeCount)
                assert(nil == lastModalName)

				Client:ToggleModalVisibility("Settings")

				print("CHANGE COUNT", changeCount, lastModalName)

				assert(2 == changeCount)
				assert("Settings" == lastModalName)

				Client:ToggleModalVisibility("Settings")

				assert(3 == changeCount)
				assert(nil == lastModalName)

                conn:Disconnect()

				Client:ToggleModalVisibility("Settings")

				assert(3 == changeCount)
				assert(nil == lastModalName)
            end)
        end)
	end)
end
