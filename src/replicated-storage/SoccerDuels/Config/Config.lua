return {
	TestingMode = (game.PlaceId == 18832664984),

	-- database
	DatabaseQueryRetries = 3,
	DatabaseRetryWaitSeconds = 2,

	-- client settings
	DefaultClientSettings = {
		["Sound Effects"] = true,
		["Low Graphics"] = false,
	},
	ClientSettingsDisplayOrder = {
		"Sound Effects",
		"Low Graphics",
	},
}
