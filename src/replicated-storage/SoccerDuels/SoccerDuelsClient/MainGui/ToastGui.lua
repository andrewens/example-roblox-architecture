-- dependency
local Debris = game:GetService("Debris")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)

-- const
local TOAST_NOTIFICATION_DURATION = Config.getConstant("ToastNotificationDurationSeconds")

-- public / Client class methods
local function newToastGui(self)
	local ToastContainer = Assets.getExpectedAsset("ToastContainer", "MainGui", self._MainGui)
	local ToastMessageTemplate = Assets.getExpectedAsset("ToastMessage", "ToastContainer", ToastContainer)

	ToastMessageTemplate.Parent = nil

	self._Maid:GiveTask(self:OnToastNotificationConnect(function(message)
		local ToastMessage = ToastMessageTemplate:Clone()
		ToastMessage.Text = message
		ToastMessage.Parent = ToastContainer

		Debris:AddItem(ToastMessage, TOAST_NOTIFICATION_DURATION)
	end))
end

return {
	new = newToastGui,
}
