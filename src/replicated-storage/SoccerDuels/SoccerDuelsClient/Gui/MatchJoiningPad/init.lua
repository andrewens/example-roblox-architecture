-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)

local TouchSensorLights = require(script.TouchSensorLights)

-- const
local COUNTDOWN_TIMER_POLL_RATE_SECONDS = Config.getConstant("MatchJoiningPadCountdownTimerPollRateSeconds")

-- public / Client class methods
local function destroyMatchJoiningPadGui(self)
	TouchSensorLights.destroy(self)
end
local function newMatchJoiningPadGui(self)
	local MatchJoiningPadGui = Assets.getExpectedAsset("MatchJoiningPadGui", "MainGui", self._MainGui)
	local Team1Container =
		Assets.getExpectedAsset("MatchJoiningPadTeam1Container", "MatchJoiningPadGui", MatchJoiningPadGui)
	local Team2Container =
		Assets.getExpectedAsset("MatchJoiningPadTeam2Container", "MatchJoiningPadGui", MatchJoiningPadGui)
	local PlayerIconTemplate =
		Assets.getExpectedAsset("MatchJoiningPadPlayerIcon", "MatchJoiningPadGui", MatchJoiningPadGui)
	local CountdownTimerLabel =
		Assets.getExpectedAsset("MatchJoiningPadCountdownTimer", "MatchJoiningPadGui", MatchJoiningPadGui)

	local UIModeMaid = Maid.new()

	local function clearMatchJoiningGui()
		for _, PlayerIcon in Team1Container:GetChildren() do
			if not (PlayerIcon.ClassName == PlayerIconTemplate.ClassName) then
				continue
			end

			PlayerIcon:Destroy()
		end

		for _, PlayerIcon in Team2Container:GetChildren() do
			if not (PlayerIcon.ClassName == PlayerIconTemplate.ClassName) then
				continue
			end

			PlayerIcon:Destroy()
		end
	end
	local function playerConnectedMatchPadChanged(Player, matchPadName, teamIndex)
		-- TODO idk why but this fires twice when a player steps on a match pad after being in lobby mode

		-- look for / destroy player icon if a player disconnected from a match joining pad
		local PlayerIcon = Team1Container:FindFirstChild(Player.Name)
		if PlayerIcon then
			PlayerIcon:Destroy()
		end

		PlayerIcon = Team2Container:FindFirstChild(Player.Name)
		if PlayerIcon then
			PlayerIcon:Destroy()
		end

		-- make a player icon if they're connected to the same match joining pad as our client
		if not (self:GetConnectedMatchPadName() == matchPadName) then
			return
		end

		PlayerIcon = PlayerIconTemplate:Clone()
		PlayerIcon.Name = Player.Name
		PlayerIcon.Parent = if teamIndex == 1 then Team1Container else Team2Container

		local LevelLabel =
			Assets.getExpectedAsset("MatchJoiningPadPlayerLevelLabel", "MatchJoiningPadPlayerIcon", PlayerIcon)
		local WinStreakLabel =
			Assets.getExpectedAsset("MatchJoiningPadPlayerWinStreakLabel", "MatchJoiningPadPlayerIcon", PlayerIcon)
		local ProfilePicture =
			Assets.getExpectedAsset("MatchJoiningPadPlayerProfilePicture", "MatchJoiningPadPlayerIcon", PlayerIcon)

		LevelLabel.Text = self:GetAnyPlayerDataValue("Level", Player)
		WinStreakLabel.Text = self:GetAnyPlayerDataValue("WinStreak", Player)
		AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(self, ProfilePicture, Player)
	end
	local function updateCountdownTimer(dt)
		local timestamp = self:GetConnectedMatchPadStateChangeTimestamp()

		if timestamp then
			local now = Time.getUnixTimestampMilliseconds()
			local deltaTime = math.ceil(math.max((timestamp - now) * 0.001, 0))

			CountdownTimerLabel.Text = deltaTime
		end

		CountdownTimerLabel.Visible = (timestamp ~= nil)
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIModeMaid:DoCleaning()

		MatchJoiningPadGui.Visible = (userInterfaceMode == "MatchJoiningPad")

		if MatchJoiningPadGui.Visible then
			UIModeMaid:GiveTask(self:OnPlayerMatchPadChangedConnect(playerConnectedMatchPadChanged))
			UIModeMaid:GiveTask(
				Utility.runServiceRenderSteppedConnect(COUNTDOWN_TIMER_POLL_RATE_SECONDS, updateCountdownTimer)
			)
			UIModeMaid:GiveTask(clearMatchJoiningGui)
		end
	end)

	self._Maid:GiveTask(UIModeMaid)

	-- clear out templates
	CountdownTimerLabel.Visible = false
	PlayerIconTemplate.Parent = nil
	clearMatchJoiningGui()

	-- modules
	TouchSensorLights.new(self)
end

return {
	destroy = destroyMatchJoiningPadGui,
	new = newMatchJoiningPadGui,
}