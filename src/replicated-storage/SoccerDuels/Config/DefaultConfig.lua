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

-- client notifications
DefaultConfig.NotificationMessages = {
	AutoSave = "Your data has been saved",
}
DefaultConfig.ToastNotificationDurationSeconds = 2

-- client settings
DefaultConfig.DefaultClientSettings = {
	["Sound Effects"] = true,
	["Low Graphics"] = false,
}
DefaultConfig.ClientSettingsDisplayOrder = {
	"Sound Effects",
	"Low Graphics",
}

-- database
DefaultConfig.DatabaseQueryRetries = 3
DefaultConfig.DatabaseRetryWaitSeconds = 2
DefaultConfig.CurrentPlayerDataVersion = 0
DefaultConfig.DefaultPlayerSaveData = {
	DataFormatVersion = DefaultConfig.CurrentPlayerDataVersion,
	Level = 0,
	WinStreak = 0,
	Settings = DefaultConfig.DefaultClientSettings,
}
DefaultConfig.AutoSavePollRateSeconds = 15
DefaultConfig.SaveDataThatPlayerDecides = {
	"Settings",
}

for _, dataFieldName in ipairs(DefaultConfig.SaveDataThatPlayerDecides) do
	DefaultConfig.SaveDataThatPlayerDecides[dataFieldName] = true
end

-- network
DefaultConfig.RemoteEventSandwichTimeoutSeconds = 60

-- settings UI
DefaultConfig.BooleanSettingOnColor3 = Color3.fromRGB(0, 255, 0) -- TODO change this to a color palette-type vibe (less specific)
DefaultConfig.BooleanSettingOffColor3 = Color3.fromRGB(255, 0, 0)

-- user input
DefaultConfig.DefaultControllerType = "Touch"
DefaultConfig.UserInputTypeToControllerType = {
	["MouseButton1"] = "Keyboard",
	["MouseButton2"] = "Keyboard",
	["MouseButton3"] = "Keyboard",
	["MouseWheel"] = "Keyboard",
	["MouseMovement"] = "Keyboard",
	["Touch"] = "Touch",
	["Keyboard"] = "Keyboard",
	["Focus"] = nil,
	["Accelerometer"] = "Touch",
	["Gyro"] = "Touch",
	["Gamepad1"] = "Gamepad",
	["Gamepad2"] = "Gamepad",
	["Gamepad3"] = "Gamepad",
	["Gamepad4"] = "Gamepad",
	["Gamepad5"] = "Gamepad",
	["Gamepad6"] = "Gamepad",
	["Gamepad7"] = "Gamepad",
	["Gamepad8"] = "Gamepad",
	["TextInput"] = nil,
	["InputMethod"] = nil,
}

return DefaultConfig
