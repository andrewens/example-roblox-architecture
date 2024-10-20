-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- public / Client class methods
local function newCareerGui(self)
	-- career modal
	local CareerModal = Assets.getExpectedAsset("CareerModal", "MainGui", self.MainGui)
	local CareerModalCloseButton = Assets.getExpectedAsset("CareerModalCloseButton", "CareerModal", CareerModal)
	local CareerModalWinRateLabel = Assets.getExpectedAsset("CareerModalWinRateLabel", "CareerModal", CareerModal)

	-- player card
	local CareerModalPlayerCard = Assets.getExpectedAsset("CareerModalPlayerCard", "CareerModal", CareerModal)
	local CareerModalPlayerCardProfilePictureImage = Assets.getExpectedAsset(
		"CareerModalPlayerCardProfilePictureImage",
		"CareerModalPlayerCard",
		CareerModalPlayerCard
	)
	local CareerModalPlayerCardUserNameLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardUserNameLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardLevelLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardLevelLabel", "CareerModalPlayerCard", CareerModalPlayerCard)

	local CareerModalPlayerCardGoalsLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardGoalsLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardAssistsLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardAssistsLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardTacklesLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardTacklesLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardWinsLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardWinsLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardLossesLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardLossesLabel", "CareerModalPlayerCard", CareerModalPlayerCard)
	local CareerModalPlayerCardWinStreakLabel =
		Assets.getExpectedAsset("CareerModalPlayerCardWinStreakLabel", "CareerModalPlayerCard", CareerModalPlayerCard)

	-- initialize
	self:OnVisibleModalChangedConnect(function(modalName)
		CareerModal.Visible = (modalName == "Career")

		if not CareerModal.Visible then
			return
		end

		-- card user
		AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(
			self,
			CareerModalPlayerCardProfilePictureImage,
			self.Player
		)
		CareerModalPlayerCardUserNameLabel.Text = self.Player.Name
		CareerModalPlayerCardLevelLabel.Text = self:GetAnyPlayerDataValue("Level", self.Player)

		-- card stats
		CareerModalPlayerCardGoalsLabel.Text = self:GetAnyPlayerDataValue("Goals", self.Player)
		CareerModalPlayerCardAssistsLabel.Text = self:GetAnyPlayerDataValue("Assists", self.Player)
		CareerModalPlayerCardTacklesLabel.Text = self:GetAnyPlayerDataValue("Tackles", self.Player)
		CareerModalPlayerCardWinsLabel.Text = self:GetAnyPlayerDataValue("Wins", self.Player)
		CareerModalPlayerCardLossesLabel.Text = self:GetAnyPlayerDataValue("Losses", self.Player)
		CareerModalPlayerCardWinStreakLabel.Text = self:GetAnyPlayerDataValue("WinStreak", self.Player)

		-- win rate
		local winRate = self:GetAnyPlayerDataValue("WinRate", self.Player)
		winRate = math.floor(winRate * 1E3) * 1E-1
		CareerModalWinRateLabel.Text = `{winRate}%`
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
