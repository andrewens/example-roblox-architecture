-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Utility = require(SoccerDuelsModule.Utility)

local ClientSettings = require(script.ClientSettings)

local MainGui = require(script.MainGui)

-- var
local ClientMetatable

-- private
local function initializeGuiWhenPlayerDataLoads(self, PlayerSaveData)
	if self._MainGui then
		return
	end
	self._MainGui = MainGui.new(self)
end

-- protected / Client network methods
local function onNotifyClient(self, toastMessage)
	for callback, _ in self._ToastCallbacks do
		callback(toastMessage)
	end
end

-- public / Client class methods
local function onClientToastNotificationConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._ToastCallbacks[callback] = true

	return {
		Disconnect = function()
			self._ToastCallbacks[callback] = nil
		end,
	}
end

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
	local s, PlayerSaveData = RemoteEvents.GetPlayerSaveData:InvokeServer(self.Player)
	if not s then
		local errorMessage = PlayerSaveData
		return false, errorMessage
	end

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

local function getClientVisibleModalName(self)
	return Enums.enumToName("ModalEnum", self._VisibleModalEnum)
end
local function clientOnVisibleModalChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	callback(getClientVisibleModalName(self))
	self._VisibleModalChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._VisibleModalChangedCallbacks[callback] = nil
		end,
	}
end
local function setClientVisibleModal(self, modalName) -- TODO this method is untested :^)
	if modalName then
		local modalEnum = Enums.getEnum("ModalEnum", modalName)
		if modalEnum == nil then
			error(`There's no Modal named "{modalName}"`)
		end

		self._VisibleModalEnum = modalEnum
	else
		self._VisibleModalEnum = nil
	end

	for callback, _ in self._VisibleModalChangedCallbacks do
		callback(getClientVisibleModalName(self))
	end
end
local function toggleClientModalVisibility(self, modalName)
	local modalEnum = Enums.getEnum("ModalEnum", modalName)
	if modalEnum == nil then
		error(`There's no Modal named "{modalName}"`)
	end

	self._VisibleModalEnum = if self._VisibleModalEnum == modalEnum then nil else modalEnum

	for callback, _ in self._VisibleModalChangedCallbacks do
		callback(getClientVisibleModalName(self))
	end
end

local function destroyClient(self) -- TODO this isn't really tested
	self._VisibleModalChangedCallbacks = {}
end

-- public
local function newClient(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player Instance!`)
	end

	-- public properties
	local self = {}
	self.Player = Player

	-- private properties (don't use outside of this module)
	self._VisibleModalEnum = nil -- int | nil
	self._VisibleModalChangedCallbacks = {} -- function callback(string visibleModalName) --> true
	self._PlayerSaveData = nil -- nil | JSON
	self._PlayerDataLoadedCallbacks = {} -- function callback(table PlayerSaveData) --> true
	self._SettingChangedCallbacks = {} -- function callback(string settingName, any settingValue) --> true
	self._ToastCallbacks = {} -- function callback(string notificationMessage) --> true
	self._MainGui = nil -- ScreenGui

	-- init
	setmetatable(self, ClientMetatable)

	self:OnPlayerSaveDataLoadedConnect(function(PlayerSaveData)
		initializeGuiWhenPlayerDataLoads(self, PlayerSaveData)
	end)
	RemoteEvents.NotifyPlayer.OnClientEvent:Connect(function(...)
		onNotifyClient(self, ...)
	end)

	return self
end
local function initializeClients()
	local ClientMethods = {
		OnToastNotificationConnect = onClientToastNotificationConnect,

		OnSettingChangedConnect = ClientSettings.onClientSettingChangedConnect,
		ToggleBooleanSetting = ClientSettings.clientToggleBooleanSetting,
		ChangeSetting = ClientSettings.clientChangeSetting,
		GetSetting = ClientSettings.getClientSettingValue,
		GetSettings = ClientSettings.getClientSettingsJson,

		OnPlayerSaveDataLoadedConnect = onClientPlayerDataLoadedConnect,
		GetPlayerSaveData = getClientPlayerSaveData,
		LoadPlayerDataAsync = loadClientPlayerDataAsync,

		OnVisibleModalChangedConnect = clientOnVisibleModalChangedConnect,
		GetVisibleModalName = getClientVisibleModalName,
		SetVisibleModalName = setClientVisibleModal,
		ToggleModalVisibility = toggleClientModalVisibility,

		Destroy = destroyClient,
	}
	ClientMetatable = { __index = ClientMethods }

	MainGui.initialize()
end

return {
	new = newClient,
	initialize = initializeClients,
}
