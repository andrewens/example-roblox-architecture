-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)

-- init
local ExpectedAssets = {}

-- root
ExpectedAssets.PlayerGui = {
	Path = "ReplicatedStorage/UserInterface",
	ClassName = "Folder",
}
ExpectedAssets.MainGui = {
	Path = "ReplicatedStorage/UserInterface/Windows",
	ClassName = "ScreenGui",
}

-- lobby modals
do
	ExpectedAssets.LobbyButtons = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Lobby/Buttons",
	}
	ExpectedAssets.ModalFrames = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames",
	}

	for _, modalName in Enums.iterateEnumsOfType("ModalEnum") do
		ExpectedAssets[`{modalName}Modal`] = {
			Path = ExpectedAssets.ModalFrames.Path .. "/" .. modalName,
		}
	end
end

-- settings modal
do
	ExpectedAssets.SettingButtonsContainer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes",
	}
	ExpectedAssets.BooleanSettingTemplate = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.BooleanSettingTemplateButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Off",
		ClassName = "ImageButton",
	}
	ExpectedAssets.BooleanSettingTemplateValue = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Off/Name",
		ClassName = "TextLabel",
	}
	ExpectedAssets.BooleanSettingTemplateName = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Option",
		ClassName = "TextLabel",
	}
	ExpectedAssets.SettingsModalCloseButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Title/Close",
		ClassName = "GuiButton",
	}
end

-- toast notifications
do
	ExpectedAssets.ToastContainer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Lobby/ToastNotification",
	}
	ExpectedAssets.ToastMessage = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Lobby/ToastNotification/Message",
		ClassName = "TextLabel",
	}
end

-- testing mode
ExpectedAssets.TestingModeLabel = {
	Path = "ReplicatedStorage/UserInterface/Windows/Middle/Lobby/TestingMode",
}

-- level / win streak overhead gui
do
	ExpectedAssets.CharacterLevelGui = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI",
		ClassName = "BillboardGui",
	}
	ExpectedAssets.OverheadWinStreakLabel = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/Stats/Winstreak/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.OverheadLevelLabel = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Level/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.OverheadNameLabel = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Display",
		ClassName = "TextLabel",
	}
	ExpectedAssets.OverheadDeviceIconContainer = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Device",
	}

	-- icon names must match the controller type enum
	ExpectedAssets.OverheadGamepadIcon = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Device/Gamepad",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.OverheadTouchIcon = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Device/Touch",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.OverheadKeyboardIcon = {
		Path = "ReplicatedStorage/UserInterface/CharacterGuiTemplate/Head/UI/User/Device/Keyboard",
		ClassName = "ImageLabel",
	}
end

-- sounds
do
	ExpectedAssets.SoundsFolder = {
		Path = "ReplicatedStorage/Sounds",
	}
	ExpectedAssets.ButtonClick = {
		Path = "ReplicatedStorage/Sounds/ButtonClick",
		ClassName = "Sound",
	}
	ExpectedAssets.ButtonMouseEnter = {
		Path = "ReplicatedStorage/Sounds/ButtonMouseEnter",
		ClassName = "Sound",
	}
end

return ExpectedAssets
