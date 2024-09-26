-- dependency
local Lighting = game:GetService("Lighting")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Maid = require(SoccerDuelsModule.Maid)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)

-- public
local function destroyMapVotingGui(self) end
local function newMapVotingGui(self)
	local MapVotingModal = Assets.getExpectedAsset("MapVotingModal", "MainGui", self._MainGui)
	local MapContainer = Assets.getExpectedAsset("MapVotingMapContainer", "MapVotingModal", MapVotingModal)
	local MapButtonTemplate = Assets.getExpectedAsset("MapVotingMapButton", "MapVotingMapContainer", MapContainer)
	local PlayerIconTemplate = Assets.getExpectedAsset("MapVotingPlayerIcon", "MapVotingMapButton", MapButtonTemplate)

	local UIMaid = Maid.new()
	local PlayerIcons -- Player --> ImageLabel

	self._Maid:GiveTask(UIMaid)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		MapVotingModal.Visible = userInterfaceMode == "MapVoting"

		if not MapVotingModal.Visible then
			return
		end

		-- render player icon for players' map votes
		PlayerIcons = {}

		UIMaid:GiveTask(self:OnConnectedMatchPadVoteChangedConnect(function(Player, mapName)
			local PlayerIcon = PlayerIcons[Player]

			if PlayerIcon == nil then
				PlayerIcon = PlayerIconTemplate:Clone()
				PlayerIcon.Name = Player.Name

				local ProfilePicture =
					Assets.getExpectedAsset("MapVotingPlayerIconProfilePicture", "MapVotingPlayerIcon", PlayerIcon)
				local Team1Gradient =
					Assets.getExpectedAsset("MapVotingPlayerIconTeam1Gradient", "MapVotingPlayerIcon", PlayerIcon)
				local Team2Gradient =
					Assets.getExpectedAsset("MapVotingPlayerIconTeam2Gradient", "MapVotingPlayerIcon", PlayerIcon)

				AvatarHeadshotImages.setImageLabelImageToAvatarHeadshot(self, ProfilePicture, Player)

				local teamIndex = self:GetPlayerTeamIndex(Player)

				Team1Gradient.Enabled = (teamIndex == 1)
				Team2Gradient.Enabled = (teamIndex == 2)

				PlayerIcons[Player] = PlayerIcon
			end

			if mapName == nil then
				PlayerIcon.Parent = nil
				return
			end

			local MapButton = MapContainer:FindFirstChild(mapName)
			if MapButton == nil then
				warn(`There is no map button named "{mapName}"`)
				return
			end

			PlayerIcon.Parent =
				Assets.getExpectedAsset("MapVotingMapButtonPlayerContainer", "MapVotingMapButton", MapButton)
		end))

		UIMaid:GiveTask(function()
			for Player, PlayerIcon in PlayerIcons do
				PlayerIcon:Destroy()
			end
			PlayerIcons = nil
		end)

		-- blur effect
		local Blur = Instance.new("BlurEffect")
		Blur.Parent = Lighting

		UIMaid:GiveTask(Blur)
	end)

	MapVotingModal.Visible = false

	MapButtonTemplate.Parent = nil
	PlayerIconTemplate.Parent = nil

	for _, MapVotingMapButton in MapContainer:GetChildren() do
		if not MapVotingMapButton:IsA(MapButtonTemplate.ClassName) then
			continue
		end

		MapVotingMapButton:Destroy()
	end

	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		local MapButton = MapButtonTemplate:Clone()
		MapButton.LayoutOrder = mapEnum
		MapButton.Name = mapName
		MapButton.Image = Config.getConstant("MapThumbnailImages", mapName)
		MapButton.Parent = MapContainer

		MapButton.Activated:Connect(function()
			self:VoteForMap(MapButton.Name)
		end)
	end
end

return {
	destroy = destroyMapVotingGui,
	new = newMapVotingGui,
}
