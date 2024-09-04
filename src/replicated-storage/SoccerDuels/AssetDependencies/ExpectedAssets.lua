-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)

-- init
local ExpectedAssets = {}

ExpectedAssets.WindowsGui = {
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

	for _, enumName in Enums.iterateEnumsOfType("ModalEnum") do
		ExpectedAssets[`{enumName}Modal`] = {
			Path = `{ExpectedAssets.ModalFrames.Path}/{enumName}`,
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
		ClassName = "ImageLabel"
	}
	ExpectedAssets.BooleanSettingTemplateButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Off",
		ClassName = "ImageButton"
	}
	ExpectedAssets.BooleanSettingTemplateValue = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Off/Name",
		ClassName = "TextLabel"
	}
	ExpectedAssets.BooleanSettingTemplateName = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Settings/Boxes/Low Graphics/Option",
		ClassName = "TextLabel"
	}
end

return ExpectedAssets
