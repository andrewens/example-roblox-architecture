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
local function initializeCharacterLevelGuis(self)
	local Folder = Instance.new("Folder")
	Folder.Name = "CharacterLevelGuis"
	Folder.Parent = self._MainGui --> gets destroyed when MainGui gets destroyed, which is when Maid does cleaning

	local OverheadGuiMaids = {}

	self._Maid:GiveTask(self:OnCharacterSpawnedInLobbyConnect(function(Character, Player)
		-- clean up last OverheadGui
		local OverheadGuiMaid = OverheadGuiMaids[Player]
		if OverheadGuiMaid then
			OverheadGuiMaid:DoCleaning()
		else
			OverheadGuiMaid = Maid.new()
			OverheadGuiMaids[Player] = OverheadGuiMaid
		end

		-- create new LevelGui
		local LevelGui = Assets.cloneExpectedAsset("CharacterLevelGui")
		LevelGui.Adornee = Character:FindFirstChild("Head")
		LevelGui.Parent = Folder

		OverheadGuiMaid:GiveTask(LevelGui)

		-- get assets
		local WinStreakLabel = Assets.getExpectedAsset("OverheadWinStreakLabel", "CharacterLevelGui", LevelGui)
		local LevelLabel = Assets.getExpectedAsset("OverheadLevelLabel", "CharacterLevelGui", LevelGui)
		local NameLabel = Assets.getExpectedAsset("OverheadNameLabel", "CharacterLevelGui", LevelGui)
		local DeviceIconContainer =
			Assets.getExpectedAsset("OverheadDeviceIconContainer", "CharacterLevelGui", LevelGui)

		-- set name
		local playerName = Player.Name --"TWENTYCHARACTERS____" (a 20 character name is a good test case here)
		local labelSizeXScale = string.len(playerName) * OVERHEAD_NAME_SCALE_PER_CHARACTER

		NameLabel.Text = playerName
		NameLabel.Size = UDim2.new(labelSizeXScale, 0, NameLabel.Size.Y.Scale, NameLabel.Size.Y.Offset)

		-- update saved player data gui when it changes
		local PlayerSaveData = self:GetPlayerSaveData(Player)
		if PlayerSaveData == nil then
			warn(`Player "{Player}" has no cached save data!`)
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
	new = initializeCharacterLevelGuis,
}
