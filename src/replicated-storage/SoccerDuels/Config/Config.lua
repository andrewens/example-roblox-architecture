local Config = {}

Config.TestingMode = (game.PlaceId == 18832664984)

-- database
Config.DatabaseQueryRetries = 3
Config.DatabaseRetryWaitSeconds = 2

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
Config.BooleanSettingOnImageId = 129188406631183
Config.BooleanSettingOffImageId = 135540289663466

return Config
