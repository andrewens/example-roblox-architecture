-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- public / Client class methods
local function newGoalCutsceneGui(self)
	local GoalCutsceneGui = Assets.getExpectedAsset("GoalCutsceneGui", "MainGui", self.MainGui)

	local GoalCutsceneGoalPlayerLabel =
		Assets.getExpectedAsset("GoalCutsceneGoalPlayerLabel", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutsceneGoalPlayerTeam1Background =
		Assets.getExpectedAsset("GoalCutsceneGoalPlayerTeam1Background", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutsceneGoalPlayerTeam2Background =
		Assets.getExpectedAsset("GoalCutsceneGoalPlayerTeam2Background", "GoalCutsceneGui", GoalCutsceneGui)

	local GoalCutsceneAssistContainer =
		Assets.getExpectedAsset("GoalCutsceneAssistContainer", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutsceneAssistLabel =
		Assets.getExpectedAsset("GoalCutsceneAssistLabel", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutsceneAssistTeam1Background =
		Assets.getExpectedAsset("GoalCutsceneAssistTeam1Background", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutsceneAssistTeam2Background =
		Assets.getExpectedAsset("GoalCutsceneAssistTeam2Background", "GoalCutsceneGui", GoalCutsceneGui)

	local GoalCutscenePlayerCard = Assets.getExpectedAsset("GoalCutscenePlayerCard", "GoalCutsceneGui", GoalCutsceneGui)
	local GoalCutscenePlayerCardProfilePictureImage = Assets.getExpectedAsset(
		"GoalCutscenePlayerCardProfilePictureImage",
		"GoalCutscenePlayerCard",
		GoalCutscenePlayerCard
	)
	local GoalCutscenePlayerCardUserNameLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardUserNameLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardLevelLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardLevelLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		GoalCutsceneGui.Visible = (userInterfaceMode == "GoalCutscene")
		if not GoalCutsceneGui.Visible then
			return
		end

		local PlayerThatScoredLastGoal = self:GetPlayerWhoScoredLastGoal()
		local PlayerThatAssistedLastGoal = self:GetPlayerWhoAssistedLastGoal()
		local teamIndex = self:GetPlayerTeamIndex(PlayerThatScoredLastGoal)

		-- goal
		GoalCutsceneGoalPlayerLabel.Text = `Scored by {PlayerThatScoredLastGoal.Name}`
		GoalCutsceneGoalPlayerTeam1Background.Enabled = (teamIndex == 1)
		GoalCutsceneGoalPlayerTeam2Background.Enabled = (teamIndex == 2)

		-- assist
		GoalCutsceneAssistContainer.Visible = PlayerThatAssistedLastGoal ~= nil
		if GoalCutsceneAssistContainer.Visible then
			GoalCutsceneAssistLabel.Text = `Assisted by {PlayerThatAssistedLastGoal.Name}`
			GoalCutsceneAssistTeam1Background.Enabled = (teamIndex == 1)
			GoalCutsceneAssistTeam2Background.Enabled = (teamIndex == 2)
		end

		-- card
		AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(
			self,
			GoalCutscenePlayerCardProfilePictureImage,
			PlayerThatScoredLastGoal
		)
		GoalCutscenePlayerCardUserNameLabel.Text = PlayerThatScoredLastGoal.Name
		GoalCutscenePlayerCardLevelLabel.Text = self:GetAnyPlayerDataValue("Level", PlayerThatScoredLastGoal)
	end)

	GoalCutsceneGui.Visible = false
end

return {
	new = newGoalCutsceneGui,
}
