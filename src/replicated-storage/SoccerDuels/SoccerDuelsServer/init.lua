local Players = game:GetService("Players")
-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Utility = require(SoccerDuelsModule.Utility)
local Database = require(script.Database)

-- const
local EXTRA_GAME_LOAD_TIME = Config.getConstant("ExtraTimeToLoadGameSeconds")
local DEFAULT_CLIENT_SETTINGS = Config.getConstant("DefaultClientSettings")

-- var
local CachedPlayerSaveData = {} -- Player --> table

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
	if EXTRA_GAME_LOAD_TIME > 0 then
		task.wait(EXTRA_GAME_LOAD_TIME)
	end

	local s, output = Database.loadPlayerSaveDataAsync(Player)
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

	return true, Utility.tableDeepCopy(PlayerSaveData) -- if we don't deep copy this, client tests on the server will use same table as server code, which incorrectly passes replication tests
end

-- public
local function getCachedPlayerSaveData(Player)
	if CachedPlayerSaveData[Player] == nil then
		return
	end

	return Utility.tableDeepCopy(CachedPlayerSaveData[Player])
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
end

return {
	getPlayerSaveData = getCachedPlayerSaveData,
	notifyPlayer = notifyPlayer,
	initialize = initializeServer,
}
