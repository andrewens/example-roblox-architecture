-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Utility = require(SoccerDuelsModule.Utility)
local ClientMapState = require(SoccerDuelsClientStateFolder.ClientMapState)

-- private
local function playerCharacterAdded(self, Player, Character)
	if self._PlayerGoals[Player] == nil then
		self._PlayerCharacterTemplate[Player] = nil
		return
	end

	if self._PlayerCharacterTemplate[Player] then
		self._PlayerCharacterTemplate[Player]:Destroy()
	end

	self._PlayerCharacterTemplate[Player] = Character:Clone()
end
local function playerJoinedConnectedMap(self, Player)
	local Character = Player.Character
	if Character == nil then
		return
	end

	self._PlayerCharacterTemplate[Player] = Character:Clone()
end
local function playerLeftConnectedMap(self, Player)
	if self._PlayerCharacterTemplate[Player] == nil then
		return
	end

	self._PlayerCharacterTemplate[Player]:Destroy()
	self._PlayerCharacterTemplate[Player] = nil
end

-- public / Client class methods
local function clonePlayerAvatar(self, Player)
	local CharacterTemplate = self._PlayerCharacterTemplate[Player]
	if CharacterTemplate == nil then
		local Character = Player.Character
		if Character == nil then
			return
		end

		return Character:Clone()
	end

	return CharacterTemplate:Clone()
end
local function initializePlayerCharactersClientModule(self)
	self.Maid:GiveTask(Utility.onCharacterLoadedConnect(function(...)
		playerCharacterAdded(self, ...)
	end))
	self.Maid:GiveTask(ClientMapState.onPlayerJoinedConnectedMap(self, function(...)
		playerJoinedConnectedMap(self, ...)
	end))
	self.Maid:GiveTask(ClientMapState.onPlayerLeftConnectedMap(self, function(...)
		playerLeftConnectedMap(self, ...)
	end))
end

return {
	clonePlayerAvatar = clonePlayerAvatar,
	initialize = initializePlayerCharactersClientModule,
}
