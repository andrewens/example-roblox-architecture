-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)

-- const
local MAX_PLAYERS_PER_TEAM = Config.getConstant("MaxPlayersPerTeam")

-- init
local ExpectedAssets = {}

-- root user interface
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
		-- note that 'LeaderboardModal' has a different path and gets overwritten later in this script
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

-- career modal
do
	ExpectedAssets.CareerModalCloseButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Title/Close",
		ClassName = "GuiButton",
	}

	-- win streak
	ExpectedAssets.CareerModalWinRateLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Winrate",
		ClassName = "TextLabel",
	}

	-- player card
	do
		ExpectedAssets.CareerModalPlayerCard = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card",
		}

		ExpectedAssets.CareerModalPlayerCardProfilePictureImage = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/PFP",
			ClassName = "ImageLabel",
		}
		ExpectedAssets.CareerModalPlayerCardUserNameLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/User",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardLevelLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Level",
			ClassName = "TextLabel",
		}

		ExpectedAssets.CareerModalPlayerCardGoalsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Goals",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardAssistsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Assists",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardTacklesLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Tackles",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardWinsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Wins",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardLossesLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Losses",
			ClassName = "TextLabel",
		}
		ExpectedAssets.CareerModalPlayerCardWinStreakLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Career/Card/Winstreak",
			ClassName = "TextLabel",
		}
	end
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
	ExpectedAssets.MatchJoiningPadBufferingImage = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/Frames/Searching/Team1/Buffering",
		ClassName = "ImageLabel",
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
	ExpectedAssets.MapVotingTimerLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Middle/MapVoting/Timer",
		ClassName = "TextLabel",
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
	ExpectedAssets.MatchJoiningPadLobbyBufferingImage = {
		Path = "ReplicatedStorage/UserInterface/Windows/Right/Player Searches/Search/Team1/Buffering",
		ClassName = "ImageLabel",
	}
end

-- practice field teleport
ExpectedAssets.PracticeFieldTeleportPart = {
	Path = "Workspace/TeleportToPracticeField",
	ClassName = "BasePart",
}

-- leave practice field gui button
do
	ExpectedAssets.LeavePracticeFieldButton = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/BackToLobby",
		ClassName = "GuiButton",
	}
end

-- maps
do
	ExpectedAssets.MapGridOriginPart = {
		Path = "Workspace/MapGridOriginPart",
		ClassName = "BasePart",
	}

	-- the MapTemplates folder is automatically moved from Workspace to ServerStorage at runtime
	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		ExpectedAssets[`{mapName} MapFolder`] = {
			Path = `ServerStorage/MapTemplates/{mapName}`,
			ConvertToClass = "Model",
		}
		ExpectedAssets[`{mapName} MapOriginPart`] = {
			Path = `ServerStorage/MapTemplates/{mapName}/Origin`,
			ClassName = "BasePart",
		}
		ExpectedAssets[`{mapName} TeamStartingPositions`] = {
			Path = `ServerStorage/MapTemplates/{mapName}/TeamStartingPositions`,
		}
		ExpectedAssets[`{mapName} SidelinesCameraPart`] = {
			Path = `ServerStorage/MapTemplates/{mapName}/Cameras/Sideline`,
			ClassName = "BasePart",
		}

		-- goal parts
		for teamIndex = 1, 2 do
			ExpectedAssets[`{mapName} Team{teamIndex} GoalPart`] = {
				Path = `ServerStorage/MapTemplates/{mapName}/Goals/Team{teamIndex}`,
				ClassName = "BasePart",
			}
		end

		-- team starting positions
		for teamIndex = 1, 2 do
			for i = 1, MAX_PLAYERS_PER_TEAM do
				ExpectedAssets[`{mapName} Team{teamIndex} StartPosition{i}`] = {
					Path = `ServerStorage/MapTemplates/{mapName}/TeamStartingPositions/Team{teamIndex}/{i}`,
					ClassName = "BasePart",
				}
			end
		end
	end
end

-- map loading screen
do
	ExpectedAssets.MapLoadingScreen = {
		Path = "ReplicatedStorage/UserInterface/LoadingScreen",
		ClassName = "ScreenGui",
	}
	ExpectedAssets.MapLoadingScreenBufferingIcon = {
		Path = "ReplicatedStorage/UserInterface/LoadingScreen/Buffering",
	}
end

-- match gameplay gui
do
	ExpectedAssets.MatchGameplayGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay",
		ClassName = "Frame",
	}
	ExpectedAssets.MatchScoreboardGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard",
		ClassName = "GuiObject",
	}

	-- timers
	do
		ExpectedAssets.MatchCountdownTimerLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Countdown",
			ClassName = "TextLabel",
		}
		ExpectedAssets.MatchScoreboardTimerLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Countdown/Timer",
			ClassName = "TextLabel",
		}
	end

	-- team players
	do
		ExpectedAssets.MatchScoreboardTeam1PlayersContainer = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/Players",
		}
		ExpectedAssets.MatchScoreboardTeam2PlayersContainer = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Blue/Players",
		}
		ExpectedAssets.MatchScoreboardPlayerIcon = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/Players/Player",
		}
		ExpectedAssets.MatchScoreboardPlayerIconLevelLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/Players/Player/Level/Value",
			ClassName = "TextLabel",
		}
		ExpectedAssets.MatchScoreboardPlayerIconProfilePicture = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/Players/Player/Pfp",
			ClassName = "ImageLabel",
		}
	end

	-- scoreboard
	do
		ExpectedAssets.MatchScoreboardTeam1BackgroundBar = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/BackgroundBar",
			ClassName = "GuiObject",
		}
		ExpectedAssets.MatchScoreboardTeam2BackgroundBar = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Blue/BackgroundBar",
			ClassName = "GuiObject",
		}
		ExpectedAssets.MatchScoreboardTeam1Score = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Red/Score",
			ClassName = "TextLabel",
		}
		ExpectedAssets.MatchScoreboardTeam2Score = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Scoreboard/Blue/Score",
			ClassName = "TextLabel",
		}
	end

	-- controls
	do
		ExpectedAssets.MatchGameplayControlsImage = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Left/Controls",
		}
		ExpectedAssets.MatchGameplaySkillsContainer = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Right",
		}
		ExpectedAssets.MatchGameplayPowerBarsContainer = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Bars",
		}
	end
end

-- match gameplay leaderboard
do
	ExpectedAssets.LeaderboardModal = {
		-- must be named 'LeaderboardModal' to overwrite the default modal path for it (see lobby modals above)
		Path = "ReplicatedStorage/UserInterface/Leaderboard",
		ClassName = "ScreenGui",
	}
	ExpectedAssets.LeaderboardRowContainer = {
		Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards",
	}
	ExpectedAssets.LeaderboardTeam1RowTemplate = {
		Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red",
	}
	ExpectedAssets.LeaderboardTeam2RowTemplate = {
		Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Blue",
	}

	-- profile pic + level
	do
		ExpectedAssets.LeaderboardRowPlayerProfilePicture = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Player/Pfp",
			ClassName = "ImageLabel",
		}
		ExpectedAssets.LeaderboardRowPlayerLevelLabel = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Player/Level/Value",
			ClassName = "TextLabel",
		}
		ExpectedAssets.LeaderboardRowPlayerNameLabel = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/User",
			ClassName = "TextLabel",
		}
	end

	-- leaderstats
	do
		ExpectedAssets.LeaderboardRowGoalsLabel = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Goals",
			ClassName = "TextLabel",
		}
		ExpectedAssets.LeaderboardRowAssistsLabel = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Assists",
			ClassName = "TextLabel",
		}
		ExpectedAssets.LeaderboardRowTacklesLabel = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Tackles",
			ClassName = "TextLabel",
		}
	end

	-- ping
	do
		ExpectedAssets.LeaderboardRowPingContainer = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Ping",
		}
		for _, pingQualityName in Enums.iterateEnumsOfType("PingQuality") do
			ExpectedAssets[`LeaderboardRow{pingQualityName}PingFrame`] = {
				Path = `ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Ping/{pingQualityName}`,
				ClassName = "GuiObject",
			}
		end
	end

	-- device
	do
		ExpectedAssets.LeaderboardRowDeviceIconContainer = {
			Path = "ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Device",
		}
		for _, controllerType in Enums.iterateEnumsOfType("ControllerType") do
			ExpectedAssets[`LeaderboardRow{controllerType}Icon`] = {
				Path = `ReplicatedStorage/UserInterface/Leaderboard/Board/Frames/Leaderboards/Red/Device/{controllerType}`,
				ClassName = "ImageLabel",
			}
		end
	end
end

-- match over gui
do
	ExpectedAssets.MatchOverGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost",
	}
	ExpectedAssets.MatchOverBar = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost/Bar",
	}
	ExpectedAssets.MatchOverResultLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost/Bar/Result",
		ClassName = "TextLabel",
	}
	ExpectedAssets.MatchOverLostGradient = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost/Bar/Lost",
		ClassName = "UIGradient",
	}
	ExpectedAssets.MatchOverWonGradient = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost/Bar/Won",
		ClassName = "UIGradient",
	}
	ExpectedAssets.MatchOverDrawGradient = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/RoundWonOrLost/Bar/Draw",
		ClassName = "UIGradient",
	}
end

-- goal cutscene gui
do
	ExpectedAssets.GoalCutsceneGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal",
	}

	-- who scored goal
	do
		ExpectedAssets.GoalCutsceneGoalPlayerLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Score/Player",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutsceneGoalPlayerTeam1Background = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Score/Red",
			ClassName = "UIGradient",
		}
		ExpectedAssets.GoalCutsceneGoalPlayerTeam2Background = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Score/Blue",
			ClassName = "UIGradient",
		}
	end

	-- who assisted the goal
	do
		ExpectedAssets.GoalCutsceneAssistContainer = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Assist",
		}
		ExpectedAssets.GoalCutsceneAssistLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Assist/Score",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutsceneAssistTeam1Background = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Assist/Red",
			ClassName = "UIGradient",
		}
		ExpectedAssets.GoalCutsceneAssistTeam2Background = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Lower/Assist/Blue",
			ClassName = "UIGradient",
		}
	end

	-- goal scoring player's stats card
	do
		ExpectedAssets.GoalCutscenePlayerCard = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card",
		}

		ExpectedAssets.GoalCutscenePlayerCardProfilePictureImage = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/PFP",
			ClassName = "ImageLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardUserNameLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/User",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardLevelLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Level",
			ClassName = "TextLabel",
		}

		ExpectedAssets.GoalCutscenePlayerCardGoalsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Goals",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardAssistsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Assists",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardTacklesLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Tackles",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardWinsLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Wins",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardLossesLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Losses",
			ClassName = "TextLabel",
		}
		ExpectedAssets.GoalCutscenePlayerCardWinStreakLabel = {
			Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/Goal/Card/Winstreak",
			ClassName = "TextLabel",
		}
	end
end

-- game over gui
do
	ExpectedAssets.GameOverGui = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver",
		ClassName = "GuiObject",
	}
	ExpectedAssets.GameOverMVPContainer = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower",
	}

	-- mvp user
	ExpectedAssets.GameOverMVPUserNameLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower/User/List/User",
		ClassName = "TextLabel",
	}
	ExpectedAssets.GameOverMVPLevelLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower/User/List/Level/Value",
		ClassName = "TextLabel",
	}

	-- mvp stats
	ExpectedAssets.GameOverMVPGoalsLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower/Stats/List/Goals/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.GameOverMVPAssistsLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower/Stats/List/Assists/Value",
		ClassName = "TextLabel",
	}
	ExpectedAssets.GameOverMVPTacklesLabel = {
		Path = "ReplicatedStorage/UserInterface/Windows/Gameplay/Middle/GameOver/Lower/Stats/List/Tackles/Value",
		ClassName = "TextLabel",
	}
end

return ExpectedAssets
