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
	ExpectedAssets.LobbyGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Lobby",
	}
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
	Path = "ReplicatedStorage/UserInterface/Windows/Left/TestingMode",
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
	ExpectedAssets.ButtonClickSound = {
		Path = "ReplicatedStorage/Sounds/ButtonClick",
		ClassName = "Sound",
	}
	ExpectedAssets.ButtonMouseEnterSound = {
		Path = "ReplicatedStorage/Sounds/ButtonMouseEnter",
		ClassName = "Sound",
	}
	ExpectedAssets.NotificationSound = {
		Path = "ReplicatedStorage/Sounds/Notification",
		ClassName = "Sound",
	}
	ExpectedAssets.StepOnMatchJoiningPadSound = {
		Path = "ReplicatedStorage/Sounds/StepOnMatchJoiningPad",
		ClassName = "Sound",
	}
end

-- match joining pads
do
	ExpectedAssets.MatchJoiningPadsFolder = {
		Path = "Workspace/MatchJoiningPads",
	}

	for i, padName in Enums.iterateEnumsOfType("MatchJoiningPad") do
		ExpectedAssets[padName] = {
			Path = "Workspace/MatchJoiningPads/" .. padName,
		}
		ExpectedAssets[padName .. " Pad1"] = {
			Path = "Workspace/MatchJoiningPads/" .. padName .. "/Pad1",
			ClassName = "BasePart",
		}
		ExpectedAssets[padName .. " Pad2"] = {
			Path = "Workspace/MatchJoiningPads/" .. padName .. "/Pad2",
			ClassName = "BasePart",
		}
		ExpectedAssets[padName .. " Pad1Light"] = {
			Path = "Workspace/MatchJoiningPads/" .. padName .. "/Pad1/Light",
			ClassName = "BasePart",
		}
		ExpectedAssets[padName .. " Pad2Light"] = {
			Path = "Workspace/MatchJoiningPads/" .. padName .. "/Pad2/Light",
			ClassName = "BasePart",
		}
	end
end

ExpectedAssets.LobbySpawnLocation = {
	Path = "Workspace/SpawnLocation",
	ClassName = "SpawnLocation",
}

-- match joining pad gui
do
	ExpectedAssets.MatchJoiningPadGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching",
	}
	ExpectedAssets.MatchJoiningPadTeam1Container = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1",
	}
	ExpectedAssets.MatchJoiningPadTeam2Container = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team2",
	}
	ExpectedAssets.MatchJoiningPadPlayerIcon = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1/Player",
	}
	ExpectedAssets.MatchJoiningPadPlayerLevelLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1/Player/Level/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.MatchJoiningPadPlayerWinStreakLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1/Player/Winstreak/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.MatchJoiningPadPlayerProfilePicture = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1/Player/Pfp",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.MatchJoiningPadCountdownTimer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/vs/Countdown",
		ClassName = "TextLabel",
	}
end

-- map voting gui
do
	ExpectedAssets.MapVotingModal = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting",
	}
	ExpectedAssets.MapVotingMapContainer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs",
	}
	ExpectedAssets.MapVotingMapButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map",
		ClassName = "ImageButton",
	}
	ExpectedAssets.MapVotingMapButtonPlayerContainer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map/Tabs",
	}
	ExpectedAssets.MapVotingPlayerIcon = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map/Tabs/Player",
	}
	ExpectedAssets.MapVotingPlayerIconProfilePicture = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map/Tabs/Player/Pfp",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.MapVotingPlayerIconTeam1Gradient = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map/Tabs/Player/Red",
		ClassName = "UIGradient",
	}
	ExpectedAssets.MapVotingPlayerIconTeam2Gradient = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Tabs/Map/Tabs/Player/Blue",
		ClassName = "UIGradient",
	}
end

-- joining match pads from lobby gui
do
	ExpectedAssets.MatchJoiningPadLobbyList = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches",
	}
	ExpectedAssets.MatchJoiningPadLobbyCard = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search",
	} -- TODO this stuff below is the same as the main match joining pad gui
	ExpectedAssets.MatchJoiningPadLobbyCardTeam1Container = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1",
	}
	ExpectedAssets.MatchJoiningPadLobbyCardTeam2Container = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team2",
	}
	ExpectedAssets.MatchJoiningPadLobbyPlayerIcon = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1/Player",
	}
	ExpectedAssets.MatchJoiningPadLobbyPlayerLevelLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1/Player/Level/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.MatchJoiningPadLobbyPlayerWinStreakLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1/Player/Winstreak/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.MatchJoiningPadLobbyPlayerProfilePicture = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1/Player/Pfp",
		ClassName = "ImageLabel",
	}
	ExpectedAssets.MatchJoiningPadLobbyCardJoinButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/vs/Join",
		ClassName = "ImageButton",
	}
end

return ExpectedAssets
