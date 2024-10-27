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

-- const
local GOAL_CUTSCENE_FRAMES_PER_SECOND = Config.getConstant("GoalCutsceneFramesPerSecond")
local GOAL_CUTSCENE_SECONDS_PER_FRAME = 1 / GOAL_CUTSCENE_FRAMES_PER_SECOND

-- public / Client class methods
local function newGoalCutsceneGui(self)
	-- gui dependencies
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

	local GoalCutscenePlayerCardGoalsLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardGoalsLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardAssistsLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardAssistsLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardTacklesLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardTacklesLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardWinsLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardWinsLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardLossesLabel =
		Assets.getExpectedAsset("GoalCutscenePlayerCardLossesLabel", "GoalCutscenePlayerCard", GoalCutscenePlayerCard)
	local GoalCutscenePlayerCardWinStreakLabel = Assets.getExpectedAsset(
		"GoalCutscenePlayerCardWinStreakLabel",
		"GoalCutscenePlayerCard",
		GoalCutscenePlayerCard
	)

	-- var
	local UIMaid = Maid.new()

	-- functions
	local function renderGoalCutsceneGui(PlayerThatScoredLastGoal, PlayerThatAssistedLastGoal, teamIndex)
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

		-- card user
		AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(
			self,
			GoalCutscenePlayerCardProfilePictureImage,
			PlayerThatScoredLastGoal
		)
		GoalCutscenePlayerCardUserNameLabel.Text = PlayerThatScoredLastGoal.Name
		GoalCutscenePlayerCardLevelLabel.Text = self:GetAnyPlayerDataValue("Level", PlayerThatScoredLastGoal)

		-- card stats
		GoalCutscenePlayerCardGoalsLabel.Text = self:GetAnyPlayerDataValue("Goals", PlayerThatScoredLastGoal)
		GoalCutscenePlayerCardAssistsLabel.Text = self:GetAnyPlayerDataValue("Assists", PlayerThatScoredLastGoal)
		GoalCutscenePlayerCardTacklesLabel.Text = self:GetAnyPlayerDataValue("Tackles", PlayerThatScoredLastGoal)
		GoalCutscenePlayerCardWinsLabel.Text = self:GetAnyPlayerDataValue("Wins", PlayerThatScoredLastGoal)
		GoalCutscenePlayerCardLossesLabel.Text = self:GetAnyPlayerDataValue("Losses", PlayerThatScoredLastGoal)
		GoalCutscenePlayerCardWinStreakLabel.Text = self:GetAnyPlayerDataValue("WinStreak", PlayerThatScoredLastGoal)
	end
	local function locallyPlayGoalCutscene(teamIndexThatScored)
		local mapName = self:GetConnectedMapName()
		local MapFolder = self:GetConnectedMapFolder()
		local otherTeamIndex = if teamIndexThatScored == 1 then 2 else 1

		local Camera = workspace.Camera
		local SidelinesCameraPart =
			Assets.getExpectedAsset(`{mapName} SidelinesCameraPart`, `{mapName} MapFolder`, MapFolder)
		local GoalPart =
			Assets.getExpectedAsset(`{mapName} Team{otherTeamIndex} GoalPart`, `{mapName} MapFolder`, MapFolder)

		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = CFrame.lookAt(SidelinesCameraPart.Position, GoalPart.Position)

		local PlayerCharacters = {} -- Player --> Character
		local cutsceneStillPlaying = true

		UIMaid:GiveTask(function()
			cutsceneStillPlaying = false
			for Player, Character in PlayerCharacters do
				Character:Destroy()
			end
		end)

		for i, PlayerCFrames, PlayerHumanoidStates in self:IterateEndOfMatchPlayerCFrames() do
			if not cutsceneStillPlaying then
				break
			end

			for Player, characterCFrame in PlayerCFrames do
				local humanoidState = PlayerHumanoidStates[Player]
				local Character = PlayerCharacters[Player]

				if Character == nil then
					Character = self:ClonePlayerAvatar(Player)
					PlayerCharacters[Player] = Character
				end

				Character:SetPrimaryPartCFrame(characterCFrame)
				Character:SetHumanoidState(humanoidState)

				print(Player.Name, humanoidState)
			end

			task.wait(GOAL_CUTSCENE_SECONDS_PER_FRAME) -- TODO this is technically a little longer b/c of how wait() works
		end
	end

	-- events
	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		GoalCutsceneGui.Visible = (userInterfaceMode == "GoalCutscene")
		if not GoalCutsceneGui.Visible then
			return
		end

		local PlayerThatScoredLastGoal = self:GetPlayerWhoScoredLastGoal()
		local PlayerThatAssistedLastGoal = self:GetPlayerWhoAssistedLastGoal()
		local teamIndex = self:GetPlayerTeamIndex(PlayerThatScoredLastGoal)

		renderGoalCutsceneGui(PlayerThatScoredLastGoal, PlayerThatAssistedLastGoal, teamIndex)
		locallyPlayGoalCutscene(teamIndex) -- this yields
	end)

	-- initialize
	GoalCutsceneGui.Visible = false
end

return {
	new = newGoalCutsceneGui,
}
