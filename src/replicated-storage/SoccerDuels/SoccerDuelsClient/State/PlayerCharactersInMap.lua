-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Utility = require(SoccerDuelsModule.Utility)
local ClientMapState = require(SoccerDuelsClientStateFolder.ClientMapState)

-- private
local function cachePlayerCharacter(self, Player, Character)
	Character = Character or Player.Character
	if Character == nil then
		return false
	end

	if Character:FindFirstChild("HumanoidRootPart") == nil then
		return false
	end

	if self._PlayerCharacterTemplate[Player] then
		self._PlayerCharacterTemplate[Player]:Destroy()
	end

	Character.Archivable = true

	local ClonedCharacter = Character:Clone()
	ClonedCharacter.HumanoidRootPart.Anchored = true
	self._PlayerCharacterTemplate[Player] = ClonedCharacter

	return true
end

-- public / Client class methods
local function clonePlayerAvatar(self, Player)
	local ClonedCharacter

	local CharacterTemplate = self._PlayerCharacterTemplate[Player]
	if CharacterTemplate == nil then
		local s = cachePlayerCharacter(self, Player)
		if not s then
			warn(`{Player.Name} has no cached character`)
			return
		end

		CharacterTemplate = self._PlayerCharacterTemplate[Player]
	end

	ClonedCharacter = CharacterTemplate:Clone()
	ClonedCharacter.PrimaryPart = ClonedCharacter:FindFirstChild("HumanoidRootPart")

	return ClonedCharacter
end
local function initializePlayerCharactersClientModule(self)
	self.Maid:GiveTask(Utility.onCharacterLoadedConnect(function(...)
		cachePlayerCharacter(self, ...)
	end))
	self.Maid:GiveTask(ClientMapState.onPlayerJoinedConnectedMap(self, function(Player, ...)
		cachePlayerCharacter(self, Player)
	end))
end

return {
	clonePlayerAvatar = clonePlayerAvatar,
	initialize = initializePlayerCharactersClientModule,
}
