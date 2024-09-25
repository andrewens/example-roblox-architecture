--[[
    Data type for holding all of a player's save data
]]

-- dependency
local HttpService = game:GetService("HttpService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)
local Time = require(SoccerDuelsModule.Time)

-- const
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")
local CURRENT_DATA_FORMAT_VERSION = Config.getConstant("DefaultPlayerSaveData", "DataFormatVersion") -- doing it this way will error if it's nil
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")

-- var
local PlayerDocumentMetatable
local PlayerDocumentMethods

-- private
local function changeNestedTableValue(self, tableName, key2, value)
	if self._Data[tableName][key2] == nil then
		error(`PlayerDocument.{tableName}["{key2}"] doesn't exist`)
	end
	if not (typeof(value) == typeof(self._Data[tableName][key2])) then
		error(`PlayerDocument.{tableName}["{key2}"] is a {typeof(self._Data[tableName][key2])}, not a {typeof(value)}`)
	end

	self._Data[tableName][key2] = value
	self._LastEditTimestamp = Time.getUnixTimestampMilliseconds()

	for callback, _ in self._DataChangedCallbacks do
		callback(tableName, self._Data[tableName])
	end
end
local function nestedTableInterface(self, tableName)
	local TableInterface = {}
	setmetatable(TableInterface, {
		__index = function(_, key2)
			return self._Data[tableName][key2]
		end,
		__newindex = function(_, key2, value)
			changeNestedTableValue(self, tableName, key2, value)
		end,
	})
	return TableInterface
end

-- public / PlayerDocument class methods
local function onPlayerDocumentValueChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for key, value in self._Data do
		callback(key, value)
	end

	self._DataChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._DataChangedCallbacks[callback] = false
		end,
	}
end
local function playerDocumentUpdateLastSavedTimestamp(self)
	self._LastSaveTimestamp = Time.getUnixTimestampMilliseconds()
end
local function playerDocumentSaveTimestampIsGreaterThanLastEditTimestamp(self)
	return self._LastSaveTimestamp >= self._LastEditTimestamp
end
local function changePlayerDocumentValue(self, key, value)
	if self._Data[key] == nil then
		error(`PlayerDocument has no field named "{key}"!`)
	end
	if typeof(self._Data[key]) ~= typeof(value) then
		error(`PlayerDocument["{key}"] is a {typeof(self._Data[key])}, not a {typeof(value)}!`)
	end

	if typeof(self._Data[key]) == "table" then
		for key2, value2 in value do
			changeNestedTableValue(self, key, key2, value2)
		end

		for callback, _ in self._DataChangedCallbacks do
			callback(key, value)
		end

		return
	end

	self._Data[key] = value
	self._LastEditTimestamp = Time.getUnixTimestampMilliseconds()

	for callback, _ in self._DataChangedCallbacks do
		callback(key, value)
	end
end
local function changeMultiplePlayerDocumentValues(self, DataToUpdate)
	if not (typeof(DataToUpdate) == "table") then
		error(`{DataToUpdate} is not a table!`)
	end

	for key, value in DataToUpdate do
		changePlayerDocumentValue(self, key, value)
	end
end
local function playerDocumentToJson(self)
	return HttpService:JSONEncode(self._Data)
end
local function playerDocumentDestroy(self)
	self._Data = nil
	self._DataChangedCallbacks = nil
	self._LastSaveTimestamp = nil
	self._LastEditTimestamp = nil
	self._NestedTableInterfaces = nil
end

-- public / PlayerDocument metamethods
local function indexPlayerDocument(self, key)
	if PlayerDocumentMethods[key] then
		return PlayerDocumentMethods[key]
	end

	if typeof(self._Data[key]) == "table" then
		return self._NestedTableInterfaces[key]
	end

	return self._Data[key]
end
local function iteratePlayerDocument(self)
	return next, self._Data
end

-- public
local function isAPlayerDocument(value)
	if not (typeof(value) == "table") then
		return false
	end

	-- TODO this should be refactored into a method that like verifies save data, and can be used in newPlayerDocument() method below
	if not (typeof(value.DataFormatVersion) == "number") then
		return false
	end
	if not (typeof(value.Level) == "number") then
		return false
	end
	if not (typeof(value.WinStreak) == "number") then
		return false
	end
	if not (typeof(value.Settings) == "table") then
		return false
	end

	return true
end
local function newPlayerDocument(LoadedSaveData)
	LoadedSaveData = LoadedSaveData or {}
	if typeof(LoadedSaveData) == "string" then
		local jsonString = LoadedSaveData
		LoadedSaveData = HttpService:JSONDecode(jsonString)
		if LoadedSaveData == nil then
			error(`"{jsonString}" is not valid JSON!`)
		end
	end
	if not (typeof(LoadedSaveData) == "table") then
		error(`{LoadedSaveData} is not a table!`)
	end

	LoadedSaveData.Settings = LoadedSaveData.Settings or {}

	local Data = Utility.tableDeepCopy(DEFAULT_PLAYER_SAVE_DATA)

	Data.DataFormatVersion = CURRENT_DATA_FORMAT_VERSION
	Data.Level = LoadedSaveData.Level or Data.Level
	Data.WinStreak = LoadedSaveData.WinStreak or Data.WinStreak

	for settingName, defaultSettingValue in DEFAULT_CLIENT_SETTINGS do
		Data.Settings[settingName] = if LoadedSaveData.Settings[settingName] == nil
			then defaultSettingValue
			else LoadedSaveData.Settings[settingName]
	end

	local self = {}
	self._Data = Data
	self._LastSaveTimestamp = 0
	self._LastEditTimestamp = 0
	self._NestedTableInterfaces = {
		-- we have to create more metatables to support self._LastEditTimestamp when editing nested tables like Settings,
		-- but all the data has to be in the _Data table to work with HttpService:JSONEncode()
		Settings = nestedTableInterface(self, "Settings"),
	}
	self._DataChangedCallbacks = {} -- function callback(string key, any value) --> true

	setmetatable(self, PlayerDocumentMetatable)

	return self
end
local function initializePlayerDocument()
	PlayerDocumentMethods = {
		OnValueChangedConnect = onPlayerDocumentValueChangedConnect,

		UpdateLastSavedTimestamp = playerDocumentUpdateLastSavedTimestamp,
		SaveTimestampIsGreaterThanLastEditTimestamp = playerDocumentSaveTimestampIsGreaterThanLastEditTimestamp,

		ChangeValues = changeMultiplePlayerDocumentValues,
		ChangeValue = changePlayerDocumentValue,

		ToJson = playerDocumentToJson,
		Destroy = playerDocumentDestroy,
	}
	PlayerDocumentMetatable = {
		__index = indexPlayerDocument,
		__newindex = changePlayerDocumentValue,
		__iter = iteratePlayerDocument,
	}
end

initializePlayerDocument()

-- TODO I feel like there should be a getSetting method here that encapsulates that behavior where clientSettings that match the default are marked as nil

return {
	new = newPlayerDocument,
	isAPlayerDocument = isAPlayerDocument,
}
