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
	ExtraSecondsInTimestamp = 0,
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

DefaultConfig.CountdownTimerFirstTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back)
DefaultConfig.CountdownTimerDurationBetweenTweensSeconds = 0.75
DefaultConfig.CountdownTimerLastTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
DefaultConfig.CountdownTimerTextSizeGoal = UDim2.new(0, 0, 0, 0)

DefaultConfig.FlashingPartTweenInfo = TweenInfo.new(0.2)
DefaultConfig.FlashingPartTransparency = 0.5

DefaultConfig.MatchJoiningPadGuiXScalePerTeamPlayer = 0.3
DefaultConfig.MatchJoiningPadGuiBaseXScale = 0.16 -- (width of the 'vs' element)

DefaultConfig.LobbyMatchJoiningPadXScalePerTeamPlayer = 0.15
DefaultConfig.LobbyMatchJoiningPadBaseXScale = 0.1 -- (width of the 'vs' element)

DefaultConfig.BufferingAnimationSoccerBallImage = "rbxassetid://5761550996" --'rbxassetid://6631155345'-- this is a white circle
DefaultConfig.BufferingAnimationSoccerBallMinSize = UDim2.new(0.2, 0, 0.2, 0)
DefaultConfig.BufferingAnimationSoccerBallMaxSize = UDim2.new(0.35, 0, 0.35, 0)
DefaultConfig.BufferingAnimationSecondsBetweenEachSoccerBallAnimation = 0.1
DefaultConfig.BufferingAnimationRestDurationSeconds = 0.5
DefaultConfig.BufferingAnimationFirstTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
DefaultConfig.BufferingAnimationLastTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- avatar headshots
DefaultConfig.AvatarHeadshotImageThumbnailType = Enum.ThumbnailType.AvatarBust
DefaultConfig.AvatarHeadshotImageThumbnailResolution = Enum.ThumbnailSize.Size100x100
DefaultConfig.AvatarHeadshotPlaceholderImage = "rbxassetid://0"

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
DefaultConfig.MatchJoiningPadRadiusPaddingStuds = 1
DefaultConfig.SecondsBetweenCheckingIfPlayerSteppedOffMatchJoiningPad = 0.25
DefaultConfig.MatchJoiningPadIdentifierAttributeName = "MatchJoiningPad"
DefaultConfig.MatchJoiningPadCountdownDurationSeconds = 3
DefaultConfig.MatchJoiningPadMapVotingDurationSeconds = 5
DefaultConfig.MatchJoiningPadStateChangePollRateSeconds = 0.2
DefaultConfig.MatchJoiningPadCountdownTimerPollRateSeconds = 0.1

-- lobby characters interacting with match joining pads & etc ("LobbyDevices")
DefaultConfig.CharacterTeleportVerticalOffset = 3
DefaultConfig.CharacterTouchSensorSizeVector3 = Vector3.new(2, 2, 2) -- Z is in forward direction of player
DefaultConfig.CharacterTouchSensorDebounceRateSeconds = 0.1
DefaultConfig.CharacterTouchSensorPartName = "TouchSensor"
DefaultConfig.LobbyDeviceCollisionGroup = "LobbyDevice"
DefaultConfig.LobbyDeviceTransparency = if DefaultConfig.TestingMode then 0.9 else 1

-- lobby characters
DefaultConfig.LobbyCharacterCollisionGroup = "LobbyCharacter"

-- maps
DefaultConfig.MapThumbnailImages = {
	["Stadium"] = "rbxassetid://113929796493700",
	["Map2"] = "rbxassetid://113929796493700",
}
DefaultConfig.MaxMapInstancesPerGridRow = 5
DefaultConfig.DistanceBetweenMapInstancesStuds = 1E3

-- match state
DefaultConfig.MapStateTickRateSeconds = 0.33
DefaultConfig.NumberOfMatchesPerGame = 5
DefaultConfig.MapLoadingDurationSeconds = 3
DefaultConfig.MatchCountdownDurationSeconds = 5
DefaultConfig.MatchGameplayDurationSeconds = 90
DefaultConfig.MatchOverDurationSeconds = 5
DefaultConfig.GameOverDurationSeconds = 5

DefaultConfig.DefaultMapInstanceOptions = {
	MatchCycleEnabled = true,
}

-- ping
DefaultConfig.PingCheckPollRateSeconds = 1
DefaultConfig.MaxPingTimeoutSeconds = 2
DefaultConfig.PingQualityThresholdMilliseconds = {
	Good = 50,
	Okay = 150, -- any ping above this is considered 'Bad'
	-- 'Bad'
}
DefaultConfig.PlaceholderPingQuality = "Bad" -- if a player has left or hasn't loaded, this is the ping quality the system will read for them

return DefaultConfig
