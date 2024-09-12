local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

return function()
	describe("ToastNotification", function()
        it("SoccerDuels.notifyPlayer() triggers Client ToastNotification event", function()
            local MockPlayer = MockInstance.new("Player")
            local Client = SoccerDuels.newClient(MockPlayer)

            local toastCount = 0
            local lastMessage
            local conn = Client:OnToastNotificationConnect(function(message)
                toastCount += 1
                lastMessage = message
            end)

            assert(toastCount == 0)
            assert(lastMessage == nil)

            SoccerDuels.notifyPlayer(MockPlayer, "This is a popup message")

            assert(toastCount == 1)
            assert(lastMessage == "This is a popup message")

            conn:Disconnect()
            SoccerDuels.notifyPlayer(MockPlayer, "The event has been disconnected")

            assert(toastCount == 1)
            assert(lastMessage == "This is a popup message")

            Client:Destroy()
        end)
    end)
end
