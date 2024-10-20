-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- public / Client class methods
local function newCareerGui(self)
	local CareerModal = Assets.getExpectedAsset("CareerModal", "MainGui", self.MainGui)
	local CareerModalCloseButton = Assets.getExpectedAsset("CareerModalCloseButton", "CareerModal", CareerModal)

	self:OnVisibleModalChangedConnect(function(modalName)
		CareerModal.Visible = (modalName == "Career")
	end)
	CareerModalCloseButton.Activated:Connect(function()
		self:SetVisibleModalName(nil)
	end)

	CareerModal.Visible = false

    UIAnimations.initializeButton(self, CareerModalCloseButton)
end

return {
	new = newCareerGui,
}
