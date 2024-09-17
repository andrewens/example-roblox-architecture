-- dependency
local RunService = game:GetService("RunService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local ClientInput = require(SoccerDuelsClientModule.ClientInput)
local ClientMatchPad = require(SoccerDuelsClientModule.ClientMatchPad)
local LobbyCharacters = require(SoccerDuelsClientModule.LobbyCharacters)
local MainGui = require(SoccerDuelsClientModule.MainGui)

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local PlayerDocument = require(SoccerDuelsModule.PlayerDocument)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local PLAYER_DECIDED_SAVE_DATA = Config.getConstant("SaveDataThatPlayerDecides")
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")

-- protected / Network methods
local function updateCachedPlayerSaveData(self, Player, key, value)
	-- band-aid fix to avoid consuming server test MockPlayer data from the RemoteEvent queue
	if RunService:IsClient() and typeof(Player) == "table" then
		return
	end

	-- avoid setting values that client decides; e.g. Settings
	if PLAYER_DECIDED_SAVE_DATA[key] then
		return
	end

	local CachedSaveData = self._PlayerSaveData[Player]
	if CachedSaveData == nil then
		CachedSaveData = PlayerDocument.new()
		self._PlayerSaveData[Player] = CachedSaveData
	end

	CachedSaveData:ChangeValue(key, value)
end

-- public / Client class methods
local function getAnyPlayerDataCachedValue(self, valueName, Player)
	if not (typeof(valueName) == "string") then
		error(`{valueName} is not a string!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if DEFAULT_PLAYER_SAVE_DATA[valueName] == nil then
		error(`"{valueName}" is not a PlayerDocument field!`)
	end

	local CachedSaveData = self._PlayerSaveData[Player]
	if CachedSaveData == nil then
		return nil
	end

	return CachedSaveData[valueName]
end
local function onClientPlayerDataLoadedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	if self._PlayerSaveData[self.Player] then
		callback(self._PlayerSaveData[self.Player])
	end

	self._PlayerDataLoadedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerDataLoadedCallbacks[callback] = nil
		end,
	}
end
local function getAnyPlayerCachedSaveData(self, Player)
	return self._PlayerSaveData[Player or self.Player]
end
local function loadClientPlayerDataAsync(self)
	self._Maid:DoCleaning()

	self._Maid:GiveTask(Network.onClientEventConnect("UpdatePlayerSaveData", self.Player, function(...)
		updateCachedPlayerSaveData(self, ...)
	end))

	local s, playerSaveDataJson = Network.invokeServer("GetPlayerSaveData", self.Player)
	if not s then
		local errorMessage = playerSaveDataJson
		return false, errorMessage
	end

	self._PlayerSaveData[self.Player] = PlayerDocument.new(playerSaveDataJson)

	MainGui.new(self)

	for callback, _ in self._PlayerDataLoadedCallbacks do
		callback(self._PlayerSaveData[self.Player])
	end

	local LoadingScreen = self.Player.PlayerGui:FindFirstChild("LoadingScreen")
	if LoadingScreen then
		LoadingScreen:Destroy()
	end

	LobbyCharacters.initialize(self)
	ClientInput.initializeClientInput(self)
	ClientMatchPad.initialize(self)

	return true
end

return {
	getAnyPlayerDataCachedValue = getAnyPlayerDataCachedValue,
	getAnyPlayerCachedSaveData = getAnyPlayerCachedSaveData,
	onClientPlayerDataLoadedConnect = onClientPlayerDataLoadedConnect,
	loadClientPlayerDataAsync = loadClientPlayerDataAsync,
}
