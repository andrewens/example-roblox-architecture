-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Network = require(SoccerDuelsModule.Network)
local PlayerDocument = require(SoccerDuelsModule.PlayerDocument)
local Utility = require(SoccerDuelsModule.Utility)

local ClientSettings = require(script.ClientSettings)
local ClientModalState = require(script.ClientModalState)
local ClientToastNotificationState = require(script.ClientToastNotificationState)
local LoadClientSaveData = require(script.LoadClientSaveData)
local LobbyCharacters = require(script.LobbyCharacters)
local MainGui = require(script.MainGui)

-- var
local ClientMetatable

-- public / Client class methods
local function destroyClient(self) -- TODO this isn't really tested
	self._Maid:DoCleaning()
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
	self._Maid = Maid.new() -- cleans on self:Destroy() and self:LoadPlayerDataAsync()
	self._VisibleModalEnum = nil -- int | nil
	self._VisibleModalChangedCallbacks = {} -- function callback(string visibleModalName) --> true
	self._PlayerSaveData = {} -- Player --> PlayerDocument
	self._PlayerDataLoadedCallbacks = {} -- function callback(table PlayerSaveData) --> true
	self._SettingChangedCallbacks = {} -- function callback(string settingName, any settingValue) --> true
	self._ToastCallbacks = {} -- function callback(string notificationMessage) --> true
	self._MainGui = nil -- ScreenGui
	self._LobbyCharacterSpawnedCallbacks = {} -- function callback(Model Character, Player PlayerThatSpawned) --> true
	self._CharactersInLobby = {} -- Player --> Character

	-- init
	setmetatable(self, ClientMetatable)

	ClientToastNotificationState.initializeClientToastNotifications(self)

	return self
end
local function initializeClients()
	local ClientMethods = {
		-- lobby characters
		GetCharactersInLobby = LobbyCharacters.getCharactersInLobby,
		OnCharacterSpawnedInLobbyConnect = LobbyCharacters.clientOnCharacterSpawnedInLobbyConnect,

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
		GetAnyPlayerDataValue = LoadClientSaveData.getAnyPlayerDataCachedValue,
		OnPlayerSaveDataLoadedConnect = LoadClientSaveData.onClientPlayerDataLoadedConnect,
		GetPlayerSaveData = LoadClientSaveData.getAnyPlayerCachedSaveData,
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
