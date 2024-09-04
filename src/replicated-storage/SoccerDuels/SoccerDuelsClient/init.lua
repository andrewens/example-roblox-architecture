-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Utility = require(SoccerDuelsModule.Utility)

local WindowsGui = require(script.WindowsGui)

-- const
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")
local CLIENT_SETTINGS_DISPLAY_ORDER = Config.getConstant("ClientSettingsDisplayOrder")

-- var
local ClientMetatable

-- private / Client class methods
local function getClientSettingValue(self, settingName)
	if self._PlayerSaveData == nil or self._PlayerSaveData.Settings[settingName] == nil then
		return DEFAULT_CLIENT_SETTINGS[settingName]
	end

	return self._PlayerSaveData.Settings[settingName]
end

-- public / Client class methods
local function clientChangeSetting(self, settingName, newValue)
	if not (typeof(settingName) == "string") then
		error(`{settingName} is not a string!`)
	end
	if newValue == nil then
		error(`Setting "{settingName}" can't be set to nil!`)
	end
	if DEFAULT_CLIENT_SETTINGS[settingName] == nil then
		error(`"{settingName}" is not a ClientSetting!`)
	end
	if self._PlayerSaveData == nil then
		error(`Player {self.Player} hasn't loaded their data yet!`)
	end

	self._PlayerSaveData.Settings[settingName] = newValue

	for callback, _ in self._SettingChangedCallbacks do
		callback(settingName, newValue)
	end
end
local function onClientSettingChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for i, settingName in CLIENT_SETTINGS_DISPLAY_ORDER do
		callback(settingName, getClientSettingValue(self, settingName))
	end

	self._SettingChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._SettingChangedCallbacks[callback] = nil
		end
	}
end
local function getClientSettingsJson(self)
	local SettingsJson = {}

	for i, settingName in CLIENT_SETTINGS_DISPLAY_ORDER do
		SettingsJson[i] = {
			Name = settingName,
			Value = getClientSettingValue(self, settingName),
		}
	end

	return SettingsJson
end

local function getClientPlayerSaveData(self)
	return self._PlayerSaveData
end
local function loadClientPlayerDataAsync(self)
	local s, PlayerSaveData = RemoteEvents.GetPlayerSaveData:InvokeServer(self.Player)

	self._PlayerSaveData = PlayerSaveData

	return s
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
local function destroyClient(self)
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
	self._SettingChangedCallbacks = {} -- function callback(string settingName, any settingValue) --> true

	-- init
	setmetatable(self, ClientMetatable)
	self._WindowsGui = WindowsGui.new(self)

	return self
end
local function initializeClients()
	local ClientMethods = {
		ChangeSetting = clientChangeSetting,
		OnSettingChangedConnect = onClientSettingChangedConnect,
		GetSettings = getClientSettingsJson,

		GetPlayerSaveData = getClientPlayerSaveData,
		LoadPlayerDataAsync = loadClientPlayerDataAsync,

		OnVisibleModalChangedConnect = clientOnVisibleModalChangedConnect,
		GetVisibleModalName = getClientVisibleModalName,
		ToggleModalVisibility = toggleClientModalVisibility,

		Destroy = destroyClient,
	}
	ClientMetatable = { __index = ClientMethods }

	WindowsGui.initialize()
end

return {
	new = newClient,
	initialize = initializeClients,
}
