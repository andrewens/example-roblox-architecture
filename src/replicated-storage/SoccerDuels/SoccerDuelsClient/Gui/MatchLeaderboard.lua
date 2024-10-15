-- dependency
local Lighting = game:GetService("Lighting")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Utility = require(SoccerDuelsModule.Utility)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)

-- const
local ROBLOX_LEADERBOARD_ENABLED_FOR_UI_MODE = Config.getConstant("RobloxLeaderboardEnabledForTheseUserInterfaceModes")

local BAD_PING_FRAME_TRANSPARENCY = Config.getConstant("LeaderboardBadPingFrameTransparency")
local GOOD_PING_FRAME_TRANSPARENCY = Config.getConstant("LeaderboardGoodPingFrameTransparency")

local BAD_PING_FRAME_COLOR = Config.getConstant("LeaderboardBadPingFrameColor")
local GOOD_PING_FRAME_COLOR = Config.getConstant("LeaderboardGoodPingFrameColor")

-- public / Client class methods
local function newMatchLeaderboardGui(self)
	local LeaderboardScreenGui = Assets.cloneExpectedAsset("LeaderboardModal")

	local LeaderstatsContainer =
		Assets.getExpectedAsset("LeaderboardRowContainer", "LeaderboardModal", LeaderboardScreenGui)
	local LeaderstatsTeam1RowTemplate =
		Assets.getExpectedAsset("LeaderboardTeam1RowTemplate", "LeaderboardModal", LeaderboardScreenGui)
	local LeaderstatsTeam2RowTemplate =
		Assets.getExpectedAsset("LeaderboardTeam2RowTemplate", "LeaderboardModal", LeaderboardScreenGui)

	local UIMaid = Maid.new()
	local PlayerLeaderstatRows = {} -- Player --> Frame

	self.Maid:GiveTask(LeaderboardScreenGui)

	local function setFrameAppearance(Frame, transparency, backgroundColor)
		Frame.Transparency = transparency
		Frame.BackgroundColor3 = backgroundColor
	end
	local function renderPlayerPingQuality(Player, pingQuality)
		local LeaderstatRow = PlayerLeaderstatRows[Player]
		if LeaderstatRow == nil then
			return
		end

		local PingContainer =
			Assets.getExpectedAsset("LeaderboardRowPingContainer", "LeaderboardTeam1RowTemplate", LeaderstatRow)

		local BadPingFrame = PingContainer.Bad
		local OkayPingFrame = PingContainer.Okay
		local GoodPingFrame = PingContainer.Good

		-- 'Good'
		if pingQuality == "Good" then
			setFrameAppearance(BadPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)
			setFrameAppearance(OkayPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)
			setFrameAppearance(GoodPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)

			return
		end

		-- 'Okay'
		if pingQuality == "Okay" then
			setFrameAppearance(BadPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)
			setFrameAppearance(OkayPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)
			setFrameAppearance(GoodPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)

			return
		end

		-- 'Bad'
		if pingQuality == "Bad" then
			setFrameAppearance(BadPingFrame, GOOD_PING_FRAME_TRANSPARENCY, GOOD_PING_FRAME_COLOR)
			setFrameAppearance(OkayPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)
			setFrameAppearance(GoodPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)

			return
		end

		-- literally anything else
		setFrameAppearance(BadPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)
		setFrameAppearance(OkayPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)
		setFrameAppearance(GoodPingFrame, BAD_PING_FRAME_TRANSPARENCY, BAD_PING_FRAME_COLOR)
	end
	local function renderPlayerControllerType(Player, controllerType)
		local LeaderstatRow = PlayerLeaderstatRows[Player]
		if LeaderstatRow == nil then
			return
		end

		local DeviceIconContainer =
			Assets.getExpectedAsset("LeaderboardRowDeviceIconContainer", "LeaderboardTeam1RowTemplate", LeaderstatRow)

		for _, DeviceIcon in DeviceIconContainer:GetChildren() do
			if DeviceIcon:IsA("ImageLabel") then
				DeviceIcon.Visible = false
			end
		end

		if controllerType == nil then
			return
		end

		local VisibleDeviceIcon = Assets.getExpectedAsset(
			`LeaderboardRow{controllerType}Icon`,
			"LeaderboardRowDeviceIconContainer",
			DeviceIconContainer
		)
		VisibleDeviceIcon.Visible = true
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		-- note that the default roblox leaderboard coregui must be disabled for Tab to work as a leaderboard keybind
		Utility.setDefaultRobloxLeaderboardEnabled(ROBLOX_LEADERBOARD_ENABLED_FOR_UI_MODE[userInterfaceMode] or false)
	end)
	self:OnVisibleModalChangedConnect(function(visibleModalName)
		UIMaid:DoCleaning()
		LeaderboardScreenGui.Enabled = (visibleModalName == "Leaderboard")

		if not LeaderboardScreenGui.Enabled then
			return
		end

		-- blur effect
		local Blur = Instance.new("BlurEffect")
		Blur.Parent = Lighting

		UIMaid:GiveTask(Blur)
	end)
	self:OnPlayerLeaderstatsChangedConnect(function(Player, teamIndex, goals, assists, tackles)
		local LeaderstatRow = PlayerLeaderstatRows[Player]

		-- destroy leaderstat row if Player left the map (teamIndex is nil)
		if teamIndex == nil then
			if LeaderstatRow then
				LeaderstatRow:Destroy()
				PlayerLeaderstatRows[Player] = nil
			end

			return
		end

		-- create new leaderstat row if it doesn't exist
		if LeaderstatRow == nil then
			local RowTemplate = if teamIndex == 1 then LeaderstatsTeam1RowTemplate else LeaderstatsTeam2RowTemplate
			LeaderstatRow = RowTemplate:Clone()

			local UserNameTextLabel =
				Assets.getExpectedAsset("LeaderboardRowPlayerNameLabel", "LeaderboardTeam1RowTemplate", LeaderstatRow)
			local ProfilePictureImage = Assets.getExpectedAsset(
				"LeaderboardRowPlayerProfilePicture",
				"LeaderboardTeam1RowTemplate",
				LeaderstatRow
			)
			local LevelLabel =
				Assets.getExpectedAsset("LeaderboardRowPlayerLevelLabel", "LeaderboardTeam1RowTemplate", LeaderstatRow)

			UserNameTextLabel.Text = Player.Name
			AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(self, ProfilePictureImage, Player)
			LevelLabel.Text = self:GetAnyPlayerDataValue("Level", Player)

			LeaderstatRow.LayoutOrder = teamIndex
			LeaderstatRow.Parent = LeaderstatsContainer

			PlayerLeaderstatRows[Player] = LeaderstatRow

			renderPlayerPingQuality(Player, self:GetPlayerPingQuality(Player))
			renderPlayerControllerType(Player, self:GetControllerType(Player))
		end

		-- update stats
		local GoalsTextLabel =
			Assets.getExpectedAsset("LeaderboardRowGoalsLabel", "LeaderboardTeam1RowTemplate", LeaderstatRow)
		local AssistsTextLabel =
			Assets.getExpectedAsset("LeaderboardRowAssistsLabel", "LeaderboardTeam1RowTemplate", LeaderstatRow)
		local TacklesTextLabel =
			Assets.getExpectedAsset("LeaderboardRowTacklesLabel", "LeaderboardTeam1RowTemplate", LeaderstatRow)

		GoalsTextLabel.Text = goals
		AssistsTextLabel.Text = assists
		TacklesTextLabel.Text = tackles
	end)
	self:OnPlayerPingQualityChangedConnect(renderPlayerPingQuality)
	self:OnControllerTypeChangedConnect(renderPlayerControllerType)

	LeaderstatsTeam1RowTemplate.Parent = nil -- note: if there are extra row templates, they don't get destroyed
	LeaderstatsTeam2RowTemplate.Parent = nil

	LeaderboardScreenGui.Enabled = false
	LeaderboardScreenGui.Parent = self.Player.PlayerGui
end

return {
	new = newMatchLeaderboardGui,
}
