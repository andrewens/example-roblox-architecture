-- dependency
local Players = game:GetService("Players")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

local Database = require(script.Database)
local TestingVariables = require(script.TestingVariables)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")
local AUTO_SAVE_RATE_SECONDS = Config.getConstant("AutoSavePollRateSeconds")
local AUTO_SAVE_MESSAGE = Config.getConstant("NotificationMessages", "AutoSave")
local PLAYER_DECIDED_SAVE_DATA = Config.getConstant("SaveDataThatPlayerDecides")

-- var
local CachedPlayerSaveData = {} -- Player --> PlayerDocument
local CharactersInLobby = {} -- Player --> Character
local PlayerControllerTypeEnums = {} -- Player --> int controllerTypeEnum

local saveAllPlayerData

-- private
local function clearPlayerControllerTypeEnum(Player)
	PlayerControllerTypeEnums[Player] = nil
	Network.fireAllClients("PlayerControllerTypeChanged", Player, nil)
end
local function lobbyCharacterDespawned(Player)
	if CharactersInLobby[Player] == nil then
		return
	end

	CharactersInLobby[Player] = nil
	Network.fireAllClients("CharacterSpawnedInLobby", Player, nil)
end
local function lobbyCharacterSpawned(Player, Character)
	CharactersInLobby[Player] = Character

	Character.Humanoid.Died:Connect(function()
		if CharactersInLobby[Player] ~= Character then
			return
		end
		lobbyCharacterDespawned(Player)
	end)

	Network.fireAllClients("CharacterSpawnedInLobby", Player, Character)
end
local function spawnCharacterInLobby(Player)
	Player:LoadCharacter()

	-- TODO ideally there should be a mock Players service so that the connection is the same...
	if TESTING_MODE and typeof(Player) == "table" then
		lobbyCharacterSpawned(Player, Player.Character)
	end
end
local function autoSaveAllPlayerData()
	while task.wait(AUTO_SAVE_RATE_SECONDS) do
		if TestingVariables.getVariable("DisableAutoSave") then
			continue
		end

		saveAllPlayerData()
	end
end

-- protected / network methods
local function playerControllerTypeChanged(Player, controllerTypeEnum)
	if CachedPlayerSaveData[Player] == nil then
		return
	end
	if not Enums.enumToName("ControllerType", controllerTypeEnum) then
		error(`{controllerTypeEnum} is not a controller type enum!`)
	end

	PlayerControllerTypeEnums[Player] = controllerTypeEnum

	Network.fireAllClients("PlayerControllerTypeChanged", Player, controllerTypeEnum)
end
local function onPlayerRequestPlayersControllerTypeEnums(RequestingPlayer)
	for OtherPlayer, controllerTypeEnum in PlayerControllerTypeEnums do
		if OtherPlayer == RequestingPlayer then
			continue
		end

		Network.fireClient("PlayerControllerTypeChanged", RequestingPlayer, OtherPlayer, controllerTypeEnum)
	end
end
local function onPlayerRequestCharactersInLobby(RequestingPlayer)
	for OtherPlayer, Character in CharactersInLobby do
		local Humanoid = Character:FindFirstChild("Humanoid")
		if Humanoid == nil or Humanoid.Health <= 0 then
			continue
		end

		Network.fireClient("CharacterSpawnedInLobby", RequestingPlayer, OtherPlayer, Character)
	end
end
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
	local testingExtraLoadTime = TestingVariables.getVariable("ExtraLoadTime")
	if testingExtraLoadTime and testingExtraLoadTime > 0 then
		TestingVariables.wait(testingExtraLoadTime)
	end

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

	-- save to server cache
	CachedPlayerSaveData[Player] = PlayerSaveData

	-- spawning character in lobby
	Utility.onPlayerDiedConnect(Player, function()
		spawnCharacterInLobby(Player)
	end)

	spawnCharacterInLobby(Player)

	return true, PlayerSaveData:ToJson()
end

-- public
local function notifyPlayer(Player, notificationMessage)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(notificationMessage) == "string") then
		error(`{notificationMessage} is not a string!`)
	end

	Network.fireClient("NotifyPlayer", Player, notificationMessage)
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

	lobbyCharacterDespawned(Player)
	clearPlayerControllerTypeEnum(Player)
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
			notifyPlayer(Player, AUTO_SAVE_MESSAGE)
		end)
	end
end
local function initializeServer()
	Database.initialize()

	Network.onServerInvokeConnect("GetPlayerSaveData", getPlayerSaveData)
	Network.onServerEventConnect("PlayerChangeSetting", playerChangedSetting)

	Players.PlayerRemoving:Connect(disconnectPlayer)

	task.spawn(autoSaveAllPlayerData)
	game:BindToClose(saveAllPlayerData)

	Network.onServerEventConnect("CharacterSpawnedInLobby", onPlayerRequestCharactersInLobby)
	Utility.onCharacterLoadedConnect(lobbyCharacterSpawned)

	Network.onServerEventConnect("PlayerControllerTypeChanged", playerControllerTypeChanged)
	Network.onServerEventConnect("GetPlayersControllerTypeEnums", onPlayerRequestPlayersControllerTypeEnums)
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
