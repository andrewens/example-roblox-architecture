-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)

-- const
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")
local CLIENT_SETTINGS_DISPLAY_ORDER = Config.getConstant("ClientSettingsDisplayOrder")

-- public
local function getClientSettingValue(self, settingName)
	if self._PlayerSaveData == nil or self._PlayerSaveData.Settings[settingName] == nil then
		return DEFAULT_CLIENT_SETTINGS[settingName]
	end

	return self._PlayerSaveData.Settings[settingName]
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
	if self._PlayerSaveData == nil then
		error(`Player {self.Player} hasn't loaded their data yet!`)
	end

	self._PlayerSaveData.Settings[settingName] = newValue

    RemoteEvents.PlayerChangeSetting:FireServer(self.Player, settingName, newValue)

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
