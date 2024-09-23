-- dependency
local Debris = game:GetService("Debris")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)

local Sounds = require(SoccerDuelsClientModule.Sounds)

-- const
local TOAST_NOTIFICATION_DURATION = Config.getConstant("ToastNotificationDurationSeconds")

-- public / Client class methods
local function destroyToastGui(self) end
local function newToastGui(self)
	local ToastContainer = Assets.getExpectedAsset("ToastContainer", "MainGui", self._MainGui)
	local ToastMessageTemplate = Assets.getExpectedAsset("ToastMessage", "ToastContainer", ToastContainer)

	ToastMessageTemplate.Parent = nil

	self:OnToastNotificationConnect(function(message)
		local ToastMessage = ToastMessageTemplate:Clone()
		ToastMessage.Text = message
		ToastMessage.Parent = ToastContainer

		Debris:AddItem(ToastMessage, TOAST_NOTIFICATION_DURATION)

		Sounds.playSound(self, "NotificationSound")
	end)
end

return {
	destroy = destroyToastGui,
	new = newToastGui,
}
