-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)

-- const
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")
local CLIENT_SETTINGS_DISPLAY_ORDER = Config.getConstant("ClientSettingsDisplayOrder")

-- public
local function getClientSettingValue(self, settingName)
	local ThisPlayersData = self._PlayerSaveData[self.Player]
	if ThisPlayersData == nil or ThisPlayersData.Settings[settingName] == nil then
		return DEFAULT_CLIENT_SETTINGS[settingName]
	end

	return ThisPlayersData.Settings[settingName]
end
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

	local ThisPlayersData = self._PlayerSaveData[self.Player]
	if ThisPlayersData == nil then
		error(`Player {self.Player} hasn't loaded their data yet!`)
	end

	ThisPlayersData.Settings[settingName] = newValue

	Network.fireServer("PlayerChangeSetting", self.Player, settingName, newValue)

	for callback, _ in self._SettingChangedCallbacks do
		callback(settingName, newValue)
	end
end
local function clientToggleBooleanSetting(self, settingName) -- TODO this method is untested :^)
	if not (typeof(settingName) == "string") then
		error(`{settingName} is not a string!`)
	end
	if not (typeof(DEFAULT_CLIENT_SETTINGS[settingName]) == "boolean") then
		error(`"{settingName}" is not a boolean ClientSetting!`)
	end

	clientChangeSetting(self, settingName, not getClientSettingValue(self, settingName))
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
		end,
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

return {
	onClientSettingChangedConnect = onClientSettingChangedConnect,
	clientToggleBooleanSetting = clientToggleBooleanSetting,
	clientChangeSetting = clientChangeSetting,
	getClientSettingValue = getClientSettingValue,
	getClientSettingsJson = getClientSettingsJson,
}
