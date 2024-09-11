-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function initializeCharacterLevelGuis(self)
	local Folder = Instance.new("Folder")
	Folder.Name = "CharacterLevelGuis"
	Folder.Parent = self._MainGui

	self._Maid:GiveTask(self:OnCharacterSpawnedInLobbyConnect(function(Character)
		local LevelGui = Assets.cloneExpectedAsset("CharacterLevelGui")
		LevelGui.Adornee = Character:FindFirstChild("Head")
		LevelGui.Parent = Folder
	end))
end

return {
	new = initializeCharacterLevelGuis,
}
