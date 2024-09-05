-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)

-- init
local ExpectedAssets = {}

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

return ExpectedAssets
