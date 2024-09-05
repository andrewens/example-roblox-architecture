local Config = {}

-- testing
Config.TestingMode = (game.PlaceId == 18832664984)
Config.ExtraTimeToLoadGameSeconds = 0

-- database
Config.DatabaseQueryRetries = 3
Config.DatabaseRetryWaitSeconds = 2
Config.CurrentPlayerDataVersion = 0
Config.DefaultPlayerSaveData = {
	DataFormatVersion = Config.CurrentPlayerDataVersion,
	Level = 0,
	WinStreak = 0,
	Settings = {},
}

-- client settings
Config.DefaultClientSettings = {
	["Sound Effects"] = true,
	["Low Graphics"] = false,
}
Config.ClientSettingsDisplayOrder = {
	"Sound Effects",
	"Low Graphics",
}

-- settings UI
Config.BooleanSettingOnColor3 = Color3.fromRGB(0, 255, 0)
Config.BooleanSettingOffColor3 = Color3.fromRGB(255, 0, 0)

return Config
