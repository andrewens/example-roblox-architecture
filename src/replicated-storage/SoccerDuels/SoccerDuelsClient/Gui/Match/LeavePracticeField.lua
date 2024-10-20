-- dependency
local SoccerDuels = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuels.AssetDependencies)

-- public / Client class methods
local function newLeavePracticeFieldGui(self)
	local LeavePracticeFieldButton = Assets.getExpectedAsset("LeavePracticeFieldButton", "MainGui", self.MainGui)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		LeavePracticeFieldButton.Visible = (userInterfaceMode == "Gameplay")
	end)

	LeavePracticeFieldButton.Activated:Connect(function()
		self:DisconnectFromAllMapInstances()
	end)

	LeavePracticeFieldButton.Visible = false
end

return {
	new = newLeavePracticeFieldGui,
}
