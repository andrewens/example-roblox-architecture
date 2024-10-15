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
local TIMER_POLL_RATE = Config.getConstant("UserInterfaceCountdownTimerPollRateSeconds")
local BACKGROUND_BAR_SIZE_SCALE_PER_PLAYER = Config.getConstant("MatchScoreboardBarSizeScalePerPlayer")
local BACKGROUND_BAR_DEFAULT_SIZE_SCALE = Config.getConstant("MatchScoreboardBarSizeScaleDefault")

local GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE = {
	["MatchCountdown"] = true,
	["MatchGameplay"] = true,
	["Gameplay"] = true,
}
local ONE_SIXTIETH = 1 / 60

-- public / Client class methods
local function newMatchLoadingScreenGui(self)
	local GameplayGui = Assets.getExpectedAsset("MatchGameplayGui", "MainGui", self.MainGui)

	local MatchCounterTextLabel = Assets.getExpectedAsset("MatchCountdownTimerLabel", "MatchGameplayGui", GameplayGui)
	local ScoreboardTimerTextLabel =
		Assets.getExpectedAsset("MatchScoreboardTimerLabel", "MatchGameplayGui", GameplayGui)

	local Team1PlayersContainer =
		Assets.getExpectedAsset("MatchScoreboardTeam1PlayersContainer", "MatchGameplayGui", GameplayGui)
	local Team2PlayersContainer =
		Assets.getExpectedAsset("MatchScoreboardTeam2PlayersContainer", "MatchGameplayGui", GameplayGui)
	local PlayerIconTemplate = Assets.getExpectedAsset("MatchScoreboardPlayerIcon", "MatchGameplayGui", GameplayGui)

	local Team1BackgroundBar =
		Assets.getExpectedAsset("MatchScoreboardTeam1BackgroundBar", "MatchGameplayGui", GameplayGui)
	local Team2BackgroundBar =
		Assets.getExpectedAsset("MatchScoreboardTeam2BackgroundBar", "MatchGameplayGui", GameplayGui)

	local Team1ScoreLabel = Assets.getExpectedAsset("MatchScoreboardTeam1Score", "MatchGameplayGui", GameplayGui)
	local Team2ScoreLabel = Assets.getExpectedAsset("MatchScoreboardTeam2Score", "MatchGameplayGui", GameplayGui)

	local UIMaid = Maid.new()
	local PlayerIcons = {} -- Player --> PlayerIcon (GuiObject)

	self.Maid:GiveTask(UIMaid)

	local function updateTimer(dt)
		local stateChangeTimestamp = self:GetConnectedMapStateChangeTimestamp()
		if stateChangeTimestamp == nil then
			ScoreboardTimerTextLabel.Text = ""
			MatchCounterTextLabel.Text = ""
			return
		end

		local now = Time.getUnixTimestampMilliseconds()
		local deltaTime = math.ceil(math.max((stateChangeTimestamp - now) * 0.001, 0)) -- seconds

		if MatchCounterTextLabel.Visible then
			MatchCounterTextLabel.Text = if deltaTime > 0 then deltaTime else ""
		end

		local mins = math.floor(deltaTime * ONE_SIXTIETH)
		local secs = deltaTime % 60

		secs = (if secs < 10 then "0" else "") .. secs

		ScoreboardTimerTextLabel.Text = `{mins}:{secs}`
	end
	local function updateTeamScoreboardBarLength(ScoreboardBackgroundBar, PlayersContainer)
		local numPlayerIcons = 0
		for Player, PlayerIcon in PlayerIcons do
			if PlayerIcon.Parent == PlayersContainer then
				numPlayerIcons += 1
			end
		end

		ScoreboardBackgroundBar.Size = UDim2.new(
			BACKGROUND_BAR_DEFAULT_SIZE_SCALE + BACKGROUND_BAR_SIZE_SCALE_PER_PLAYER * numPlayerIcons,
			0,
			1,
			0
		)
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		GameplayGui.Visible = GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE[userInterfaceMode] or false
		MatchCounterTextLabel.Visible = (userInterfaceMode == "MatchCountdown")

		if GameplayGui.Visible then
			UIMaid:GiveTask(Utility.runServiceRenderSteppedConnect(TIMER_POLL_RATE, updateTimer))
		end
	end)
	self:OnPlayerJoinedConnectedMap(function(Player, teamIndex)
		local ScoreboardBackgroundBar = if teamIndex == 1 then Team1BackgroundBar else Team2BackgroundBar
		local PlayersContainer = if teamIndex == 1 then Team1PlayersContainer else Team2PlayersContainer

		local PlayerIcon = PlayerIcons[Player]
		if PlayerIcon then
			PlayerIcon:Destroy()
			PlayerIcons[Player] = nil -- (just in case)
		end

		PlayerIcon = PlayerIconTemplate:Clone()

		local ProfilePictureImageLabel =
			Assets.getExpectedAsset("MatchScoreboardPlayerIconProfilePicture", "MatchScoreboardPlayerIcon", PlayerIcon)
		local LevelTextLabel =
			Assets.getExpectedAsset("MatchScoreboardPlayerIconLevelLabel", "MatchScoreboardPlayerIcon", PlayerIcon)

		AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(self, ProfilePictureImageLabel, Player)
		LevelTextLabel.Text = self:GetAnyPlayerDataValue("Level", Player)
		PlayerIcon.Parent = PlayersContainer

		PlayerIcons[Player] = PlayerIcon

		updateTeamScoreboardBarLength(ScoreboardBackgroundBar, PlayersContainer)
	end)
	self:OnPlayerLeftConnectedMap(function(Player)
		local PlayerIcon = PlayerIcons[Player]
		if PlayerIcon == nil then
			return
		end

		local PlayersContainer = PlayerIcon.Parent
		local ScoreboardBackgroundBar = if PlayersContainer == Team1PlayersContainer
			then Team1BackgroundBar
			else Team2BackgroundBar

		PlayerIcon:Destroy()
		PlayerIcons[Player] = nil

		updateTeamScoreboardBarLength(ScoreboardBackgroundBar, PlayersContainer)
	end)
	self:OnConnectedMapScoreChanged(function(team1Score, team2Score)
		Team1ScoreLabel.Text = team1Score
		Team2ScoreLabel.Text = team2Score
	end)

	GameplayGui.Visible = false
	PlayerIconTemplate.Parent = nil

	for _, PlayerIcon in Team1PlayersContainer:GetChildren() do
		if not PlayerIcon:IsA(PlayerIconTemplate.ClassName) then
			continue
		end

		PlayerIcon:Destroy()
	end
	for _, PlayerIcon in Team2PlayersContainer:GetChildren() do
		if not PlayerIcon:IsA(PlayerIconTemplate.ClassName) then
			continue
		end

		PlayerIcon:Destroy()
	end

	UIAnimations.initializeTimer(self, MatchCounterTextLabel)
end

return {
	new = newMatchLoadingScreenGui,
}
