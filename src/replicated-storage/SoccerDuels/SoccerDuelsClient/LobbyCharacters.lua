-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

local ClientMatchPad = require(SoccerDuelsClientModule.ClientMatchPad)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local CHARACTER_TOUCH_SENSOR_DEBOUNCE_RATE_SECONDS = Config.getConstant("CharacterTouchSensorDebounceRateSeconds")
local LOBBY_DEVICE_COLLISION_GROUP = Config.getConstant("LobbyDeviceCollisionGroup")
local LOBBY_DEVICE_TRANSPARENCY = Config.getConstant("LobbyDeviceTransparency")
local CHARACTER_TOUCH_SENSOR_PART_NAME = Config.getConstant("CharacterTouchSensorPartName")

-- private / Client class methods
local partTouchedClientLobbyCharacter
local function initializeClientLobbyCharacter(self, Character)
	-- band-aid to prevent this code from running in server tests
	if typeof(Character) == "table" then
		return
	end

	local TouchSensorPart = Character[CHARACTER_TOUCH_SENSOR_PART_NAME]

	Utility.onPartTouchedConnect(TouchSensorPart, CHARACTER_TOUCH_SENSOR_DEBOUNCE_RATE_SECONDS, function(TouchingPart)
		partTouchedClientLobbyCharacter(self, TouchingPart)
	end)
end

-- protected / Network methods
local function characterSpawnedInLobby(self, OtherPlayer, Character)
	if Utility.shouldIgnoreMockPlayerFromServerTests(OtherPlayer) then
		return
	end

	if self._CharactersInLobby[OtherPlayer] == Character then
		return
	end

	self._CharactersInLobby[OtherPlayer] = Character

	if Character == nil then
		return
	end

	if OtherPlayer == self.Player then
		initializeClientLobbyCharacter(self, Character)
	end

	for callback, _ in self._LobbyCharacterSpawnedCallbacks do
		callback(Character, OtherPlayer)
	end
end

-- public / Client class methods
function partTouchedClientLobbyCharacter(self, TouchingPart)
	ClientMatchPad.touchedMatchJoiningPadPart(self, TouchingPart)
end
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
	self._Maid:GiveTask(Network.onClientEventConnect("CharacterSpawnedInLobby", self.Player, function(...)
		characterSpawnedInLobby(self, ...)
	end))

	Network.fireServer("CharacterSpawnedInLobby", self.Player)
end

return {
	partTouchedClientLobbyCharacter = partTouchedClientLobbyCharacter,
	getCharactersInLobby = getCharactersInLobby,
	clientOnCharacterSpawnedInLobbyConnect = clientOnCharacterSpawnedInLobbyConnect,
	initialize = initializeLobbyCharactersCache,
}
