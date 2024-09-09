--[[
    Data type for holding all of a player's save data
]]

-- dependency
local HttpService = game:GetService("HttpService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")
local CURRENT_DATA_FORMAT_VERSION = Config.getConstant("DefaultPlayerSaveData", "DataFormatVersion") -- doing it this way will error if it's nil
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")

-- var
local PlayerDocumentMetatable

-- public / PlayerDocument class methods
local function playerDocumentToJson(self)
	return HttpService:JSONEncode(self)
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

	local self = Utility.tableDeepCopy(DEFAULT_PLAYER_SAVE_DATA)

	self.DataFormatVersion = CURRENT_DATA_FORMAT_VERSION
	self.Level = LoadedSaveData.Level or self.Level
	self.WinStreak = LoadedSaveData.WinStreak or self.WinStreak

	if LoadedSaveData.Settings then
		for settingName, defaultSettingValue in DEFAULT_CLIENT_SETTINGS do
			local loadedSettingValue = LoadedSaveData.Settings[settingName]
			if loadedSettingValue == nil or loadedSettingValue == defaultSettingValue then
				continue
			end

			self.Settings[settingName] = loadedSettingValue
		end
	end

	setmetatable(self, PlayerDocumentMetatable)

	return self
end
local function initializePlayerDocument()
	local PlayerDocumentMethods = {
		ToJson = playerDocumentToJson,
	}
	PlayerDocumentMetatable = { __index = PlayerDocumentMethods }
end

initializePlayerDocument()

-- TODO I feel like there should be a getSetting method here that encapsulates that behavior where clientSettings that match the default are marked as nil

return {
	new = newPlayerDocument,
	isAPlayerDocument = isAPlayerDocument,
}
