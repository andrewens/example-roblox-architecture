-- dependency
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)

-- const
local OVERHEAD_NAME_SCALE_PER_CHARACTER = Config.getConstant("OverheadNameXScalePerCharacter")

-- public / Client class methods
local function newCharacterHeadGui(self)
	-- TODO this whole thing would be simplified a lot (no maids, no tables, etc)
	-- if there was a "OnAnyPlayerSaveDataChangedConnect" method and a "IsPlayerInLobby" method

	local Folder = Instance.new("Folder")
	Folder.Name = "CharacterLevelGuis"
	Folder.Parent = self._MainGui --> gets destroyed when MainGui gets destroyed, which is when Maid does cleaning

	local OverheadGuiMaids = {} -- Player --> Maid
	local OverheadGuis = {} -- Player --> BillboardGui

	local function updatePlayerDeviceIcon(Player, controllerType)
		local OverheadGui = OverheadGuis[Player]
		if OverheadGui == nil then
			return
		end

		local DeviceIconContainer =
			Assets.getExpectedAsset("OverheadDeviceIconContainer", "CharacterLevelGui", OverheadGui)

		for _, DeviceIcon in DeviceIconContainer:GetChildren() do
			if not DeviceIcon:IsA("ImageLabel") then
				continue
			end

			DeviceIcon.Visible = DeviceIcon.Name == controllerType
		end
	end

	self._Maid:GiveTask(self:OnCharacterSpawnedInLobbyConnect(function(Character, Player)
		-- clean up last OverheadGui
		local OverheadGuiMaid = OverheadGuiMaids[Player]
		if OverheadGuiMaid then
			OverheadGuiMaid:DoCleaning()
		else
			OverheadGuiMaid = Maid.new()
			OverheadGuiMaids[Player] = OverheadGuiMaid
		end

		-- create new LevelGui & store it
		local LevelGui = Assets.cloneExpectedAsset("CharacterLevelGui")
		LevelGui.Adornee = Character:FindFirstChild("Head")
		LevelGui.Parent = Folder

		OverheadGuiMaid:GiveTask(LevelGui)

		OverheadGuis[Player] = LevelGui
		OverheadGuiMaid:GiveTask(function()
			if OverheadGuis[Player] == LevelGui then
				OverheadGuis[Player] = nil
			end
		end)

		-- get assets
		local WinStreakLabel = Assets.getExpectedAsset("OverheadWinStreakLabel", "CharacterLevelGui", LevelGui)
		local LevelLabel = Assets.getExpectedAsset("OverheadLevelLabel", "CharacterLevelGui", LevelGui)
		local NameLabel = Assets.getExpectedAsset("OverheadNameLabel", "CharacterLevelGui", LevelGui)

		-- set name
		local playerName = Player.Name --"TWENTYCHARACTERS____" (a 20 character name is a good test case here)
		local labelSizeXScale = string.len(playerName) * OVERHEAD_NAME_SCALE_PER_CHARACTER

		NameLabel.Text = playerName
		NameLabel.Size = UDim2.new(labelSizeXScale, 0, NameLabel.Size.Y.Scale, NameLabel.Size.Y.Offset)

		-- update device for first time
		updatePlayerDeviceIcon(Player, self:GetControllerType(Player))

		-- update saved player data gui when it changes
		local PlayerSaveData = self:GetPlayerSaveData(Player)
		if PlayerSaveData == nil then
			warn(`Player "{Player.Name}" has no cached save data!`)
			return
		end

		OverheadGuiMaid:GiveTask(PlayerSaveData:OnValueChangedConnect(function(key, value)
			if key == "WinStreak" then
				WinStreakLabel.Text = value
			elseif key == "Level" then
				LevelLabel.Text = value
			end
		end))
	end))

	self._Maid:GiveTask(self:OnControllerTypeChangedConnect(updatePlayerDeviceIcon))

	-- cleanup
	self._Maid:GiveTask(function()
		for Player, OverheadGuiMaid in OverheadGuiMaids do
			OverheadGuiMaid:DoCleaning()
		end
		OverheadGuiMaids = nil
	end)

	self._Maid:GiveTask(Players.PlayerRemoving:Connect(function(Player)
		local OverheadGuiMaid = OverheadGuiMaids[Player]
		if OverheadGuiMaid then
			OverheadGuiMaid:DoCleaning()
			OverheadGuiMaids[Player] = nil
		end
	end))
end

return {
	new = newCharacterHeadGui,
}
