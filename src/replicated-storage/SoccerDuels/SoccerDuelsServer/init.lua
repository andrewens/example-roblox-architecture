-- dependency
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

local Database = require(script.Database)
local CharacterServer = require(script.CharacterServer)
local MapsServer = require(script.MapsServer)
local MatchJoiningPadsServer = require(script.MatchJoiningPadsServer)
local NotifyPlayerServer = require(script.NotifyPlayerServer)
local PlayerControllerTypeServer = require(script.PlayerControllerTypeServer)
local PlayerRegionServer = require(script.PlayerRegionServer)
local PlayerPingServer = require(script.PlayerPingServer)
local PracticeFieldServer = require(script.PracticeFieldServer)
local TestingVariables = require(script.TestingVariables)
local SoccerBallServer = require(script.SoccerBallServer)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")
local AUTO_SAVE_RATE_SECONDS = Config.getConstant("AutoSavePollRateSeconds")
local AUTO_SAVE_MESSAGE = Config.getConstant("NotificationMessages", "AutoSave")
local PLAYER_DECIDED_SAVE_DATA = Config.getConstant("SaveDataThatPlayerDecides")

-- var
local CachedPlayerSaveData = {} -- Player --> PlayerDocument

local saveAllPlayerData

-- private
local function autoSaveAllPlayerData()
	while task.wait(AUTO_SAVE_RATE_SECONDS) do
		if TestingVariables.getVariable("DisableAutoSave") then
			continue
		end

		saveAllPlayerData()
	end
end

-- protected / network methods
local function playerChangedSetting(Player, settingName, newValue)
	local PlayerSaveData = CachedPlayerSaveData[Player]
	if PlayerSaveData == nil then
		return
	end

	if DEFAULT_CLIENT_SETTINGS[settingName] == nil then
		error(`Player {Player} attempted to change setting "{settingName}", which doesn't exist`)
	end
	if typeof(newValue) ~= typeof(DEFAULT_CLIENT_SETTINGS[settingName]) then
		error(`"{settingName}" is a {typeof(DEFAULT_CLIENT_SETTINGS[settingName])}, not a {typeof(newValue)}`)
	end

	PlayerSaveData.Settings[settingName] = newValue
end
local function getPlayerSaveData(Player)
	-- testing latency
	local testingExtraLoadTime = TestingVariables.getVariable("ExtraLoadTime")
	if testingExtraLoadTime and testingExtraLoadTime > 0 then
		TestingVariables.wait(testingExtraLoadTime)
	end

	-- attempt to load player save data
	local s, PlayerSaveData = pcall(Database.getPlayerSaveDataAsync, Player)
	if not s then
		local errorMessage = PlayerSaveData
		Player:Kick(`Failed to load your saved data: {errorMessage}`)

		return false, errorMessage
	end

	-- updating all clients' caches (including our Player's) with our new player's data
	PlayerSaveData:OnValueChangedConnect(function(key, value)
		Network.fireAllClients("UpdatePlayerSaveData", Player, key, value)
	end)

	for OtherPlayer, OtherSaveData in CachedPlayerSaveData do
		-- ** intentionally, this doesn't include our Player yet

		for key, value in OtherSaveData do
			if PLAYER_DECIDED_SAVE_DATA[key] then
				continue
			end

			Network.fireClient("UpdatePlayerSaveData", Player, OtherPlayer, key, value)
		end
	end

	-- network event so clients know a new player joined (TODO this behavior is untested)
	Network.fireAllClients("PlayerConnected", Player)

	for OtherPlayer, _ in CachedPlayerSaveData do
		Network.fireClient("PlayerConnected", Player, OtherPlayer)
	end

	-- save to server cache
	CachedPlayerSaveData[Player] = PlayerSaveData

	-- other systems
	PlayerPingServer.playerDataLoaded(Player)
	CharacterServer.playerDataLoaded(Player)
	MatchJoiningPadsServer.playerDataLoaded(Player)
	PlayerRegionServer.playerDataLoaded(Player)

	return true, PlayerSaveData:ToJson()
end

-- public
local function playerDataIsLoaded(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return CachedPlayerSaveData[Player] ~= nil
end
local function getLoadedPlayers()
	local LoadedPlayers = {}

	for Player, _ in CachedPlayerSaveData do
		table.insert(LoadedPlayers, Player)
	end

	return LoadedPlayers
end
local function playerDataIsSaved(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local CachedSaveData = CachedPlayerSaveData[Player]
	if CachedSaveData == nil then
		error(`{Player}'s save data is not cached!`)
	end

	return CachedSaveData:SaveTimestampIsGreaterThanLastEditTimestamp()
end
local function disconnectPlayer(Player, kickPlayer)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player!`)
	end
	if kickPlayer and Players:FindFirstChild(Player.Name) then
		Player:Kick("You have been disconnected by the server")
	end

	local CachedSaveData = CachedPlayerSaveData[Player]
	if CachedSaveData then
		if CachedSaveData:SaveTimestampIsGreaterThanLastEditTimestamp() then
			task.spawn(CachedSaveData.Destroy, CachedSaveData)
		else
			task.spawn(function()
				Database.savePlayerDataAsync(Player, CachedSaveData)
				CachedSaveData:Destroy()
			end)
		end
	end

	CachedPlayerSaveData[Player] = nil

	PlayerControllerTypeServer.disconnectPlayer(Player)
	MatchJoiningPadsServer.disconnectPlayer(Player)
	CharacterServer.disconnectPlayer(Player)
	PlayerPingServer.disconnectPlayer(Player)
	MapsServer.disconnectPlayer(Player)
	PlayerRegionServer.disconnectPlayer(Player)

	Network.fireAllClients("PlayerDisconnected", Player) -- TODO this behavior is untested
end
local function disconnectAllPlayers(kickPlayers)
	for Player, _ in CachedPlayerSaveData do
		disconnectPlayer(Player, kickPlayers)
	end
end
local function updateCachedPlayerSaveData(Player, DataToUpdate)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(DataToUpdate) == "table") then
		error(`{DataToUpdate} is not a table!`)
	end

	local CachedSaveData = CachedPlayerSaveData[Player]
	if CachedSaveData == nil then
		error(`{Player}'s save data is not cached!`)
	end

	CachedSaveData:ChangeValues(DataToUpdate)
end
local function incrementCachedPlayerSaveData(Player, DataToUpdate)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(DataToUpdate) == "table") then
		error(`{DataToUpdate} is not a table!`)
	end

	local CachedSaveData = CachedPlayerSaveData[Player]
	if CachedSaveData == nil then
		error(`{Player}'s save data is not cached!`)
	end

	for key, value in DataToUpdate do
		if not (typeof(value) == "number") then
			error(`"{key}": {value} is not a number!`)
		end

		local currentValue = CachedSaveData[key]
		if not (typeof(currentValue) == "number") then
			error(`SaveData["{key}"] is not a number!`)
		end

		DataToUpdate[key] = currentValue + value
	end

	CachedSaveData:ChangeValues(DataToUpdate)
end
local function getCachedPlayerSaveData(Player)
	if CachedPlayerSaveData[Player] == nil then
		return
	end

	return CachedPlayerSaveData[Player]
end
function saveAllPlayerData()
	for Player, CachedSaveData in CachedPlayerSaveData do
		if playerDataIsSaved(Player) then
			continue
		end

		task.spawn(function()
			Database.savePlayerDataAsync(Player, CachedSaveData) -- this could error but that's ok
			NotifyPlayerServer.notifyPlayer(Player, AUTO_SAVE_MESSAGE)
		end)
	end
end
local function initializeServer()
	Database.initialize()

	Network.onServerInvokeConnect("GetPlayerSaveData", getPlayerSaveData)
	Network.onServerEventConnect("PlayerChangeSetting", playerChangedSetting)

	Network.onServerEventConnect("ClientDestroyed", disconnectPlayer)
	Players.PlayerRemoving:Connect(disconnectPlayer)

	task.spawn(autoSaveAllPlayerData)
	game:BindToClose(saveAllPlayerData)

	PlayerControllerTypeServer.initialize()
	MatchJoiningPadsServer.initialize()
	PracticeFieldServer.initialize()
	PlayerPingServer.initialize()
	SoccerBallServer.initialize()
	CharacterServer.initialize()
	MapsServer.initialize()

	script.Parent = ServerScriptService -- prevent exploiters from accessing server code
end

return {
	-- characters
	teleportPlayerToPosition = CharacterServer.teleportPlayerToPosition,
	getPlayerPosition = CharacterServer.getPlayerPosition,
	getPlayerCFrame = CharacterServer.getPlayerCFrame,

	-- database
	getAvailableDataStoreRequests = Database.getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = Database.getPlayerSaveDataAsync,
	savePlayerDataAsync = Database.savePlayerDataAsync,

	-- maps
	disconnectPlayerFromAllMapInstances = MapsServer.disconnectPlayerFromAllMapInstances,
	getPlayersConnectedToMapInstance = MapsServer.getPlayersConnectedToMapInstance,
	getPlayerConnectedMapInstance = MapsServer.getPlayerConnectedMapInstance,
	connectPlayerToMapInstance = MapsServer.connectPlayerToMapInstance,
	playerIsInLobby = MapsServer.playerIsInLobby,

	destroyAllMapInstances = MapsServer.destroyAllMapInstances,
	getAllMapInstances = MapsServer.getAllMapInstances,

	getMapInstanceStartingLocation = MapsServer.getMapInstanceStartingLocation,
	getPlayerThatScoredLastGoal = MapsServer.getPlayerThatScoredLastGoal,
	getMapInstanceWinningTeam = MapsServer.getMapInstanceWinningTeam,
	getMapInstanceMapName = MapsServer.getMapInstanceMapName,
	getMapInstanceFolder = MapsServer.getMapInstanceFolder,
	getMapInstanceOrigin = MapsServer.getMapInstanceOrigin,
	getMapInstanceScore = MapsServer.getMapInstanceScore,
	destroyMapInstance = MapsServer.destroyMapInstance,
	newMapInstance = MapsServer.newMapInstance,

	-- map state
	getMapInstanceState = MapsServer.getMapInstanceState,
	getPlayerTeamIndex = MapsServer.getPlayerTeamIndex,
	mapTimerTick = MapsServer.mapTimerTick,

	playerTackledAnotherPlayer = MapsServer.playerTackledAnotherPlayer,
	playerAssistedGoal = MapsServer.playerAssistedGoal,
	playerScoredGoal = MapsServer.playerScoredGoal,

	-- map voting
	getMatchPadWinningMapVote = MatchJoiningPadsServer.getMatchPadWinningMapVote,
	getMatchPadMapVotes = MatchJoiningPadsServer.getMatchPadMapVotes,

	-- match joining pads
	teleportPlayerToLobbySpawnLocation = MatchJoiningPadsServer.teleportPlayerToLobbySpawnLocation,
	teleportPlayerToMatchPad = MatchJoiningPadsServer.teleportPlayerToMatchPad,
	matchPadTimerTick = MatchJoiningPadsServer.matchPadTimerTick,

	getPlayerConnectedMatchPadName = MatchJoiningPadsServer.getPlayerConnectedMatchPadName,
	getPlayerConnectedMatchPadTeam = MatchJoiningPadsServer.getPlayerConnectedMatchPadTeam,
	getMatchPadTeamPlayers = MatchJoiningPadsServer.getMatchPadTeamPlayers,
	getMatchJoiningPads = MatchJoiningPadsServer.getMatchJoiningPads,
	getMatchPadState = MatchJoiningPadsServer.getMatchPadState,

	-- ping
	getPlayerPingMilliseconds = PlayerPingServer.getPlayerPingMilliseconds,
	getPlayerPingQuality = PlayerPingServer.getPlayerPingQuality,
	pingPlayerAsync = PlayerPingServer.pingPlayerAsync,

	-- player region
	getPlayerRegion = PlayerRegionServer.getPlayerRegion,

	-- testing
	resetAvailableDataStoreRequestsTestingMode = TestingVariables.resetAvailableDataStoreRequestsTestingMode,
	addExtraSecondsForTesting = TestingVariables.addExtraSecondsForTesting,
	resetTestingVariables = TestingVariables.resetVariables,
	getTestingVariable = TestingVariables.getVariable,
	setTestingVariable = TestingVariables.setVariable,
	wait = TestingVariables.wait,

	-- toast notifications
	notifyPlayer = NotifyPlayerServer.notifyPlayer,

	-- soccer ball
	teleportSoccerBallToPosition = SoccerBallServer.teleportSoccerBallToPosition,
	getPlayerPossessedBallId = SoccerBallServer.getPlayerPossessedBallId,
	getSoccerBallParentMapId = SoccerBallServer.getSoccerBallParentMapId,
	getSoccerBallPosition = SoccerBallServer.getSoccerBallPosition,
	playerKickSoccerBall = SoccerBallServer.playerKickSoccerBall,
	soccerBallStateTick = SoccerBallServer.soccerBallStateTick,
	getSoccerBallOwner = SoccerBallServer.getSoccerBallOwner,
	getSoccerBallState = SoccerBallServer.getSoccerBallState,
	soccerPhysicsStep = SoccerBallServer.soccerPhysicsStep,
	destroySoccerBall = SoccerBallServer.destroySoccerBall,
	newSoccerBall = SoccerBallServer.newSoccerBall,

	-- SoccerDuels server
	incrementCachedPlayerSaveData = incrementCachedPlayerSaveData,
	updateCachedPlayerSaveData = updateCachedPlayerSaveData,
	getCachedPlayerSaveData = getCachedPlayerSaveData,
	disconnectAllPlayers = disconnectAllPlayers,
	playerDataIsLoaded = playerDataIsLoaded,
	playerDataIsSaved = playerDataIsSaved,
	saveAllPlayerData = saveAllPlayerData,
	getLoadedPlayers = getLoadedPlayers,
	disconnectPlayer = disconnectPlayer,
	initialize = initializeServer,
}
