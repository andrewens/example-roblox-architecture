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
local GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE = {
	["MatchCountdown"] = true,
	["MatchGameplay"] = true,
	["Gameplay"] = true,
}
local TIMER_POLL_RATE = Config.getConstant("UserInterfaceCountdownTimerPollRateSeconds")
local ONE_SIXTIETH = 1 / 60

-- public / Client class methods
local function newMatchLoadingScreenGui(self)
	local GameplayGui = Assets.getExpectedAsset("MatchGameplayGui", "MainGui", self._MainGui)
	local MatchCounterTextLabel = Assets.getExpectedAsset("MatchCountdownTimerLabel", "MatchGameplayGui", GameplayGui)
	local ScoreboardTimerTextLabel =
		Assets.getExpectedAsset("MatchScoreboardTimerLabel", "MatchGameplayGui", GameplayGui)
	local Team1PlayersContainer =
		Assets.getExpectedAsset("MatchScoreboardTeam1PlayersContainer", "MatchGameplayGui", GameplayGui)
	local Team2PlayersContainer =
		Assets.getExpectedAsset("MatchScoreboardTeam2PlayersContainer", "MatchGameplayGui", GameplayGui)
	local PlayerIconTemplate = Assets.getExpectedAsset("MatchScoreboardPlayerIcon", "MatchGameplayGui", GameplayGui)

	local UIMaid = Maid.new()
	local PlayerIcons = {} -- Player --> PlayerIcon (GuiObject)

	self._Maid:GiveTask(UIMaid)

	local function updateTimer(dt)
		local now = Time.getUnixTimestampMilliseconds()
		local stateChangeTimestamp = self:GetConnectedMapStateChangeTimestamp()
		local deltaTime = math.ceil(math.max((stateChangeTimestamp - now) * 0.001, 0)) -- seconds

		if MatchCounterTextLabel.Visible then
			MatchCounterTextLabel.Text = if deltaTime > 0 then deltaTime else ""
		end

		local mins = math.floor(deltaTime * ONE_SIXTIETH)
		local secs = deltaTime % 60

		secs = (if secs < 10 then "0" else "") .. secs

		ScoreboardTimerTextLabel.Text = `{mins}:{secs}`
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
		PlayerIcon.Parent = if teamIndex == 1 then Team1PlayersContainer else Team2PlayersContainer

		PlayerIcons[Player] = PlayerIcon
	end)
	self:OnPlayerLeftConnectedMap(function(Player)
		local PlayerIcon = PlayerIcons[Player]
		if PlayerIcon then
			PlayerIcon:Destroy()
			PlayerIcons[Player] = nil
		end
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
