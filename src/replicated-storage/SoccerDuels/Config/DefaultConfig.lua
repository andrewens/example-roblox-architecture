--[[
	DO NOT EDIT THIS SCRIPT IN ROBLOX STUDIO!

	It is checked into the git repository for this game.
	Any edits to this script will be overwritten by changes
	made to the git repository.

	Instead, edit the Config module script in ReplicatedStorage:

		ReplicatedStorage/Config

	Any key/value pairs in that script will override values
	here IF THEY HAVE THE EXACT SAME NAME.

	(double-check to make sure that you match the name exactly;
	 there are no errors to tell you if you did it correctly)

	September 5, 2024
	Andrew Ens
]]

local DefaultConfig = {}

-- testing
DefaultConfig.TestingMode = (game.PlaceId == 18832664984)
DefaultConfig.TestingVariables = {
	ExtraLoadTime = 0,
	TimeTravel = false,
	NetworkAutoFail = false,
	SimulateDataStoreBudget = false,
	DataStoreRequestBudget = {
		Save = 0,
		Load = 0,
	},
	DisableAutoSave = false,
}

-- database
DefaultConfig.DatabaseQueryRetries = 3
DefaultConfig.DatabaseRetryWaitSeconds = 2
DefaultConfig.CurrentPlayerDataVersion = 0
DefaultConfig.DefaultPlayerSaveData = {
	DataFormatVersion = DefaultConfig.CurrentPlayerDataVersion,
	Level = 0,
	WinStreak = 0,
	Settings = {},
}
DefaultConfig.AutoSavePollRateSeconds = 5

-- client settings
DefaultConfig.DefaultClientSettings = {
	["Sound Effects"] = true,
	["Low Graphics"] = false,
}
DefaultConfig.ClientSettingsDisplayOrder = {
	"Sound Effects",
	"Low Graphics",
}

-- settings UI
DefaultConfig.BooleanSettingOnColor3 = Color3.fromRGB(0, 255, 0) -- TODO change this to a color palette-type vibe (less specific)
DefaultConfig.BooleanSettingOffColor3 = Color3.fromRGB(255, 0, 0)

return DefaultConfig
