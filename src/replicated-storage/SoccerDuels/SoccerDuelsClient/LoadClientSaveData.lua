-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local LobbyCharacters = require(SoccerDuelsClientModule.LobbyCharacters)
local MainGui = require(SoccerDuelsClientModule.MainGui)

local Network = require(SoccerDuelsModule.Network)
local PlayerDocument = require(SoccerDuelsModule.PlayerDocument)

-- public / Client class methods
local function onClientPlayerDataLoadedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	if self._PlayerSaveData then
		callback(self._PlayerSaveData)
	end

	self._PlayerDataLoadedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerDataLoadedCallbacks[callback] = nil
		end,
	}
end
local function getClientPlayerSaveData(self)
	return self._PlayerSaveData
end
local function loadClientPlayerDataAsync(self)
	self._Maid:DoCleaning()

	local s, playerSaveDataJson = Network.invokeServer("GetPlayerSaveData", self.Player)
	if not s then
		local errorMessage = playerSaveDataJson
		return false, errorMessage
	end

	local PlayerSaveData = PlayerDocument.new(playerSaveDataJson)
	self._PlayerSaveData = PlayerSaveData

	MainGui.new(self)

	for callback, _ in self._PlayerDataLoadedCallbacks do
		callback(PlayerSaveData)
	end

	local LoadingScreen = self.Player.PlayerGui:FindFirstChild("LoadingScreen")
	if LoadingScreen then
		LoadingScreen:Destroy()
	end

	LobbyCharacters.initialize(self)

	return true
end

return {
	getClientPlayerSaveData = getClientPlayerSaveData,
	onClientPlayerDataLoadedConnect = onClientPlayerDataLoadedConnect,
	loadClientPlayerDataAsync = loadClientPlayerDataAsync,
}
