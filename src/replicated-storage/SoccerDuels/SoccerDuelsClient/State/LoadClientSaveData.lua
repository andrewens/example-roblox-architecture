-- dependency
local RunService = game:GetService("RunService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local ClientInput = require(SoccerDuelsClientStateFolder.ClientInput)
local ClientMatchPad = require(SoccerDuelsClientStateFolder.ClientMatchPad)
local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)
local LobbyCharacters = require(SoccerDuelsClientStateFolder.LobbyCharacters)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

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
local function clientPlayerDataIsLoaded(self)
	return self._PlayerSaveData[self.Player] ~= nil
end
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

	ClientMatchPad.initialize(self) -- must be before GetPlayerSaveData b/c it listens to a remote event that fires afterward
	AvatarHeadshotImages.initialize(self)
	UIAnimations.initialize(self)

	local s, playerSaveDataJson = Network.invokeServer("GetPlayerSaveData", self.Player)
	if not s then
		local errorMessage = playerSaveDataJson
		return false, errorMessage
	end

	self._PlayerSaveData[self.Player] = PlayerDocument.new(playerSaveDataJson)

	for callback, _ in self._PlayerDataLoadedCallbacks do
		callback(self._PlayerSaveData[self.Player])
	end

	local LoadingScreen = self.Player.PlayerGui:FindFirstChild("LoadingScreen")
	if LoadingScreen then
		LoadingScreen:Destroy()
	end

	LobbyCharacters.initialize(self)
	ClientInput.initializeClientInput(self)

	ClientUserInterfaceMode.setClientUserInterfaceMode(self, "Lobby")

	return true
end

return {
	clientPlayerDataIsLoaded = clientPlayerDataIsLoaded,
	getAnyPlayerDataCachedValue = getAnyPlayerDataCachedValue,
	getAnyPlayerCachedSaveData = getAnyPlayerCachedSaveData,
	onClientPlayerDataLoadedConnect = onClientPlayerDataLoadedConnect,
	loadClientPlayerDataAsync = loadClientPlayerDataAsync,
}
