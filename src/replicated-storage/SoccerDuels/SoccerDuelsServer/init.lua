-- dependency
local Players = game:GetService("Players")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Utility = require(SoccerDuelsModule.Utility)

local Database = require(script.Database)
local TestingVariables = require(script.TestingVariables)

-- const
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")

-- var
local CachedPlayerSaveData = {} -- Player --> PlayerDocument

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

	-- TODO save to database
end
local function getPlayerSaveData(Player)
	local testingExtraLoadTime = TestingVariables.getVariable("ExtraLoadTime")
	if testingExtraLoadTime and testingExtraLoadTime > 0 then
		TestingVariables.wait(testingExtraLoadTime)
	end

	local s, output = pcall(Database.getPlayerSaveDataAsync, Player)
	if not s then
		Player:Kick(`Failed to load your saved data: {output}`)
		return false, output
	end

	local PlayerSaveData = output
	CachedPlayerSaveData[Player] = PlayerSaveData

	Utility.onPlayerDiedConnect(Player, function()
		Player:LoadCharacter()
	end)

	Player:LoadCharacter()

	return true, PlayerSaveData
end

-- public
local function getLoadedPlayers()
	local LoadedPlayers = {}

	for Player, _ in CachedPlayerSaveData do
		table.insert(LoadedPlayers, Player)
	end

	return LoadedPlayers
end
local function disconnectPlayer(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player!`)
	end
	if Players:FindFirstChild(Player.Name) then
		Player:Kick("You have been disconnected by the server")
	end

	CachedPlayerSaveData[Player] = nil
end
local function disconnectAllPlayers()
	for Player, _ in CachedPlayerSaveData do
		disconnectPlayer(Player)
	end
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
local function getCachedPlayerSaveData(Player)
	if CachedPlayerSaveData[Player] == nil then
		return
	end

	return CachedPlayerSaveData[Player]
end
local function saveAllPlayerData()
	if Database.getAvailableDataStoreRequests("Save") <= 0 then
		return false
	end

	for Player, CachedSaveData in CachedPlayerSaveData do
		if playerDataIsSaved(Player) then
			continue
		end

		task.spawn(Database.savePlayerDataAsync, Player, CachedSaveData)
	end

	return true
end
local function notifyPlayer(Player, notificationMessage)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(notificationMessage) == "string") then
		error(`{notificationMessage} is not a string!`)
	end

	RemoteEvents.NotifyPlayer:FireClient(Player, notificationMessage)
end
local function initializeServer()
	Database.initialize()

	RemoteEvents.GetPlayerSaveData.OnServerInvoke = getPlayerSaveData
	RemoteEvents.PlayerChangeSetting.OnServerEvent:Connect(playerChangedSetting)

	Players.PlayerRemoving:Connect(disconnectPlayer)
end

return {
	-- database
	getAvailableDataStoreRequests = Database.getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = Database.getPlayerSaveDataAsync,
	savePlayerDataAsync = Database.savePlayerDataAsync,

	-- testing API
	wait = TestingVariables.wait,
	getTestingVariable = TestingVariables.getVariable,
	setTestingVariable = TestingVariables.setVariable,
	resetTestingVariables = TestingVariables.resetVariables,
	resetAvailableDataStoreRequestsTestingMode = TestingVariables.resetAvailableDataStoreRequestsTestingMode,

	-- SoccerDuels server
	getLoadedPlayers = getLoadedPlayers,
	disconnectPlayer = disconnectPlayer,
	disconnectAllPlayers = disconnectAllPlayers,
	saveAllPlayerData = saveAllPlayerData,
	playerDataIsSaved = playerDataIsSaved,
	updateCachedPlayerSaveData = updateCachedPlayerSaveData,
	getCachedPlayerSaveData = getCachedPlayerSaveData,
	notifyPlayer = notifyPlayer,
	initialize = initializeServer,
}
