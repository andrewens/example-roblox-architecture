--[[
    Data type for holding all of a player's save data
]]

-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")
local CURRENT_DATA_FORMAT_VERSION = Config.getConstant("DefaultPlayerSaveData", "DataFormatVersion") -- doing it this way will error if it's nil
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")

-- public
local function newPlayerDocument(LoadedSaveData)
	LoadedSaveData = LoadedSaveData or {}
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

	return self
end

-- TODO I feel like there should be a getSetting method here that encapsulates that behavior where clientSettings that match the default are marked as nil

return {
	new = newPlayerDocument,
}
