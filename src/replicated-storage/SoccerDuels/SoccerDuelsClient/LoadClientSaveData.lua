-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
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
	local s, playerSaveDataJson = RemoteEvents.GetPlayerSaveData:InvokeServer(self.Player)
	if not s then
		local errorMessage = playerSaveDataJson
		return false, errorMessage
	end

	local PlayerSaveData = PlayerDocument.new(playerSaveDataJson)
	self._PlayerSaveData = PlayerSaveData

	for callback, _ in self._PlayerDataLoadedCallbacks do
		callback(PlayerSaveData)
	end

	local LoadingScreen = self.Player.PlayerGui:FindFirstChild("LoadingScreen")
	if LoadingScreen then
		LoadingScreen:Destroy()
	end

	return true
end

return {
	getClientPlayerSaveData = getClientPlayerSaveData,
	onClientPlayerDataLoadedConnect = onClientPlayerDataLoadedConnect,
	loadClientPlayerDataAsync = loadClientPlayerDataAsync,
}
