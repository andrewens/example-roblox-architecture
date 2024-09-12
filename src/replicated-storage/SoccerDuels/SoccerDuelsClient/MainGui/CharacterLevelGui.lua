-- dependency
local Players = game:GetService("Players")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Maid = require(SoccerDuelsModule.Maid)

-- public / Client class methods
local function initializeCharacterLevelGuis(self)
	local Folder = Instance.new("Folder")
	Folder.Name = "CharacterLevelGuis"
	Folder.Parent = self._MainGui

	local OverheadGuiMaids = {}

	self._Maid:GiveTask(self:OnCharacterSpawnedInLobbyConnect(function(Character, Player)
		local OverheadGuiMaid = OverheadGuiMaids[Player]
		if OverheadGuiMaid then
			OverheadGuiMaid:DoCleaning()
		else
			OverheadGuiMaid = Maid.new()
			OverheadGuiMaids[Player] = OverheadGuiMaid
		end

		local LevelGui = Assets.cloneExpectedAsset("CharacterLevelGui")
		LevelGui.Adornee = Character:FindFirstChild("Head")
		LevelGui.Parent = Folder

		OverheadGuiMaid:GiveTask(LevelGui)

		local WinStreakLabel = Assets.getExpectedAsset("OverheadWinStreakLabel", "CharacterLevelGui", LevelGui)
		local LevelLabel = Assets.getExpectedAsset("OverheadLevelLabel", "CharacterLevelGui", LevelGui)

		local PlayerSaveData = self:GetPlayerSaveData(Player)
		if PlayerSaveData == nil then
			error(`Player "{Player}" has no cached save data!`)
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
