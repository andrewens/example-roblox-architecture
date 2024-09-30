-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const
local MATCH_JOINING_PAD_GUI_X_SCALE_PER_TEAM_PLAYER = Config.getConstant("LobbyMatchJoiningPadXScalePerTeamPlayer")
local MATCH_JOINING_PAD_GUI_BASE_X_SCALE = Config.getConstant("LobbyMatchJoiningPadBaseXScale")

-- public / Client class methods
local function newAvailableMatchJoiningPadsGui(self)
	local MatchPadsListContainer = Assets.getExpectedAsset("MatchJoiningPadLobbyList", "MainGui", self._MainGui)
	local MatchPadCardTemplate =
		Assets.getExpectedAsset("MatchJoiningPadLobbyCard", "MatchJoiningPadLobbyList", MatchPadsListContainer)
	local PlayerIconTemplate =
		Assets.getExpectedAsset("MatchJoiningPadLobbyPlayerIcon", "MatchJoiningPadLobbyCard", MatchPadCardTemplate)

	local UIMaid = Maid.new()

	local PlayerIcons -- Player --> PlayerIcon
	local PreviousPlayerMatchPad -- Player --> string matchPadName

	local function clearMatchPadsListContainer()
		for i, MatchPadCard in MatchPadsListContainer:GetChildren() do
			if not MatchPadCard:IsA(MatchPadCardTemplate.ClassName) then
				continue
			end

			MatchPadCard:Destroy()
		end
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		if not (userInterfaceMode == "Lobby") then
			return
		end

		PlayerIcons = {}
		PreviousPlayerMatchPad = {}

		UIMaid:GiveTask(self:OnPlayerMatchPadChangedConnect(function(Player, matchPadName, teamIndex)
			-- create PlayerIcon if it doesn't exist
			local PlayerIcon = PlayerIcons[Player]
			if PlayerIcon == nil or PlayerIcon.Parent == nil then
				PlayerIcon = PlayerIconTemplate:Clone()
				PlayerIcon.Name = Player.Name

				local LevelLabel = Assets.getExpectedAsset(
					"MatchJoiningPadLobbyPlayerLevelLabel",
					"MatchJoiningPadLobbyPlayerIcon",
					PlayerIcon
				)
				local WinStreakLabel = Assets.getExpectedAsset(
					"MatchJoiningPadLobbyPlayerWinStreakLabel",
					"MatchJoiningPadLobbyPlayerIcon",
					PlayerIcon
				)
				local ProfilePictureImage = Assets.getExpectedAsset(
					"MatchJoiningPadLobbyPlayerProfilePicture",
					"MatchJoiningPadLobbyPlayerIcon",
					PlayerIcon
				)

				LevelLabel.Text = self:GetAnyPlayerDataValue("Level", Player)
				WinStreakLabel.Text = self:GetAnyPlayerDataValue("WinStreak", Player)
				AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(self, ProfilePictureImage, Player)

				PlayerIcons[Player] = PlayerIcon
			end

			-- destroy now-empty lobby cards and make once-full lobby cards visible again
			local prevMatchPadName = PreviousPlayerMatchPad[Player]
			if prevMatchPadName then
				local MatchPadLobbyCard = MatchPadsListContainer:FindFirstChild(prevMatchPadName)
				if MatchPadLobbyCard then
					if self:MatchPadIsEmpty(prevMatchPadName) then
						PlayerIcon.Parent = nil -- avoid accidentally deleting our PlayerIcon
						MatchPadLobbyCard:Destroy()
					else
						MatchPadLobbyCard.Visible = true
					end
				end
			end

			PreviousPlayerMatchPad[Player] = matchPadName

			-- remove player icon
			if matchPadName == nil then
				PlayerIcon:Destroy()
				PlayerIcons[Player] = nil
				return
			end

			-- create lobby card if it doesn't exist
			local MatchPadLobbyCard = MatchPadsListContainer:FindFirstChild(matchPadName)
			if MatchPadLobbyCard == nil then
				local maxPlayersPerTeam = self:GetMatchPadMaxPlayersPerTeam(matchPadName)

				MatchPadLobbyCard = MatchPadCardTemplate:Clone()
				MatchPadLobbyCard.Name = matchPadName
				MatchPadLobbyCard.Size = UDim2.new(
					MATCH_JOINING_PAD_GUI_BASE_X_SCALE + maxPlayersPerTeam * MATCH_JOINING_PAD_GUI_X_SCALE_PER_TEAM_PLAYER,
					MatchPadLobbyCard.Size.X.Offset,
					MatchPadLobbyCard.Size.Y.Scale,
					MatchPadLobbyCard.Size.Y.Offset
				)
				MatchPadLobbyCard.Parent = MatchPadsListContainer

				local JoinButton = Assets.getExpectedAsset(
					"MatchJoiningPadLobbyCardJoinButton",
					"MatchJoiningPadLobbyCard",
					MatchPadLobbyCard
				)
				JoinButton.Activated:Connect(function()
					self:TeleportToMatchPadAsync(MatchPadLobbyCard.Name)
				end)

				UIAnimations.initializeButton(self, JoinButton)
			end

			-- put player in that lobby card
			local containerName = `MatchJoiningPadLobbyCardTeam{teamIndex}Container`
			PlayerIcon.Parent = Assets.getExpectedAsset(containerName, "MatchJoiningPadLobbyCard", MatchPadLobbyCard)

			-- make full match pads invisible
			MatchPadLobbyCard.Visible = not self:MatchPadIsFull(matchPadName)
		end))

		UIMaid:GiveTask(function()
			PlayerIcons = nil
			PreviousPlayerMatchPad = nil
		end)

		UIMaid:GiveTask(clearMatchPadsListContainer)
	end)

    self._Maid:GiveTask(UIMaid)

	-- clear templates
	PlayerIconTemplate.Parent = nil
	MatchPadCardTemplate.Parent = nil

	clearMatchPadsListContainer()

	local TemplateTeam1Container = Assets.getExpectedAsset(
		"MatchJoiningPadLobbyCardTeam1Container",
		"MatchJoiningPadLobbyCard",
		MatchPadCardTemplate
	)
	local TemplateTeam2Container = Assets.getExpectedAsset(
		"MatchJoiningPadLobbyCardTeam2Container",
		"MatchJoiningPadLobbyCard",
		MatchPadCardTemplate
	)

	for i, PlayerIcon in TemplateTeam1Container:GetChildren() do
		if not PlayerIcon:IsA(PlayerIconTemplate.ClassName) then
			continue
		end

		PlayerIcon:Destroy()
	end
	for i, PlayerIcon in TemplateTeam2Container:GetChildren() do
		if not PlayerIcon:IsA(PlayerIconTemplate.ClassName) then
			continue
		end

		PlayerIcon:Destroy()
	end
end

return {
	new = newAvailableMatchJoiningPadsGui,
}
