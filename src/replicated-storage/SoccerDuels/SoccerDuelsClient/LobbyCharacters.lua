-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Network = require(SoccerDuelsModule.Network)

-- public / Client class methods
local function getCharactersInLobby(self)
	return table.clone(self._CharactersInLobby)
end
local function clientOnCharacterSpawnedInLobbyConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._LobbyCharacterSpawnedCallbacks[callback] = true

	for OtherPlayer, Character in self._CharactersInLobby do
		callback(Character, OtherPlayer)
	end

	return {
		Disconnect = function()
			self._LobbyCharacterSpawnedCallbacks[callback] = nil
		end,
	}
end
local function initializeLobbyCharactersCache(self)
	local conn = Network.onClientEventConnect("CharacterSpawnedInLobby", self.Player, function(OtherPlayer, Character)
		self._CharactersInLobby[OtherPlayer] = Character

		if Character == nil then
			return
		end

		for callback, _ in self._LobbyCharacterSpawnedCallbacks do
			callback(Character, OtherPlayer)
		end
	end)
	Network.fireServer("CharacterSpawnedInLobby", self.Player)

	self._Maid:GiveTask(conn)
end

return {
	getCharactersInLobby = getCharactersInLobby,
	clientOnCharacterSpawnedInLobbyConnect = clientOnCharacterSpawnedInLobbyConnect,
	initialize = initializeLobbyCharactersCache,
}
