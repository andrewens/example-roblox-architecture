-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Utility = require(SoccerDuelsModule.Utility)

local ClientSettings = require(script.ClientSettings)
local ClientModalState = require(script.ClientModalState)
local ClientToastNotificationState = require(script.ClientToastNotificationState)
local LoadClientSaveData = require(script.LoadClientSaveData)
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

-- public / Client class methods
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
	ClientToastNotificationState.initializeClientToastNotifications(self)

	return self
end
local function initializeClients()
	local ClientMethods = {
		-- toast notification
		OnToastNotificationConnect = ClientToastNotificationState.onClientToastNotificationConnect,

		-- modal state
		OnVisibleModalChangedConnect = ClientModalState.clientOnVisibleModalChangedConnect,
		GetVisibleModalName = ClientModalState.getClientVisibleModalName,
		SetVisibleModalName = ClientModalState.setClientVisibleModal,
		ToggleModalVisibility = ClientModalState.toggleClientModalVisibility,

		-- client settings
		OnSettingChangedConnect = ClientSettings.onClientSettingChangedConnect,
		ToggleBooleanSetting = ClientSettings.clientToggleBooleanSetting,
		ChangeSetting = ClientSettings.clientChangeSetting,
		GetSetting = ClientSettings.getClientSettingValue,
		GetSettings = ClientSettings.getClientSettingsJson,

		-- loading player save data
		OnPlayerSaveDataLoadedConnect = LoadClientSaveData.onClientPlayerDataLoadedConnect,
		GetPlayerSaveData = LoadClientSaveData.getClientPlayerSaveData,
		LoadPlayerDataAsync = LoadClientSaveData.loadClientPlayerDataAsync,

		-- client root
		Destroy = destroyClient,
	}
	ClientMetatable = { __index = ClientMethods }

	MainGui.initialize()
end

return {
	new = newClient,
	initialize = initializeClients,
}
