-- dependency
local Debris = game:GetService("Debris")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)

-- const
local TOAST_NOTIFICATION_DURATION = Config.getConstant("ToastNotificationDurationSeconds")

-- public
local function newToastGui(Client, MainGui)
    local ToastContainer = Assets.getExpectedAsset("ToastContainer", "MainGui", MainGui)
    local ToastMessageTemplate = Assets.getExpectedAsset("ToastMessage", "ToastContainer", ToastContainer)

    ToastMessageTemplate.Parent = nil

    Client:OnToastNotificationConnect(function(message)
        local ToastMessage = ToastMessageTemplate:Clone()
        ToastMessage.Text = message
        ToastMessage.Parent = ToastContainer

        Debris:AddItem(ToastMessage, TOAST_NOTIFICATION_DURATION)
    end)
end

return {
    new = newToastGui,
}
