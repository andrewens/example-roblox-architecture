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

-- color palette
DefaultConfig.BooleanSettingOnColor3 = Color3.fromRGB(0, 255, 0) -- TODO change this to a color palette-type vibe (less specific)
DefaultConfig.BooleanSettingOffColor3 = Color3.fromRGB(255, 0, 0)

DefaultConfig.Team1Color = Color3.new(1, 0, 0)
DefaultConfig.Team2Color = Color3.new(0, 1, 1)

-- user interface
DefaultConfig.OverheadNameXScalePerCharacter = 0.03 -- be careful -- long usernames can make the level / device icons invisible

DefaultConfig.ButtonClickTweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Quart)
DefaultConfig.ButtonClickSize = UDim2.new(0.9, 0, 0.9, 0) -- size is relative to its original size
DefaultConfig.ButtonCenterYScale = 0.7 -- this decides where buttons are centered for animations. 0.5 for dead center, 0 for top, 1 for bottom

DefaultConfig.ButtonMouseOverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
DefaultConfig.ButtonMouseOverPositionOffset = UDim2.new(0, 0, -0.1, 0) -- (remember, negative Y is up)
DefaultConfig.ButtonMouseOverSize = UDim2.new(1.1, 0, 1.1, 0)

DefaultConfig.PopupVisibleTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back)
DefaultConfig.PopupStartPositionOffset = UDim2.new(0, 0, 0.05, 0) -- (negative Y is still up)
DefaultConfig.PopupStartSizeRatio = 0.6 -- 1 for same size as normal, 0.5 for half-size, etc

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

-- match joining pads
DefaultConfig.MatchJoiningPadRadiusPaddingStuds = 3 -- to account for differences in player position on server and client, and avoid needlessly teleporting the player when they touch a pad
DefaultConfig.SecondsBetweenCheckingIfPlayerSteppedOffMatchJoiningPad = 0.25
DefaultConfig.MatchJoiningPadIdentifierAttributeName = "MatchJoiningPad"

-- lobby characters interacting with match joining pads, ... etc "LobbyDevices"
DefaultConfig.CharacterTouchSensorSizeVector3 = Vector3.new(6, 7, 3) -- Z is in forward direction of player
DefaultConfig.CharacterTouchSensorDebounceRateSeconds = 0.1
DefaultConfig.CharacterTouchSensorPartName = "TouchSensor"
DefaultConfig.LobbyDeviceCollisionGroup = "LobbyDevice"
DefaultConfig.LobbyDeviceTransparency = if DefaultConfig.TestingMode then 0.9 else 1

return DefaultConfig
