-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Utility = require(SoccerDuelsModule.Utility)
local Database = require(script.Database)

-- const
local EXTRA_GAME_LOAD_TIME = Config.getConstant("ExtraTimeToLoadGameSeconds")

-- protected / network methods
local function getPlayerSaveData(Player)
    if EXTRA_GAME_LOAD_TIME > 0 then
        task.wait(EXTRA_GAME_LOAD_TIME)
    end

    local s, output = Database.loadPlayerSaveDataAsync(Player)
    if not s then
        Player:Kick(`Failed to load your saved data: {output}`)

        return false, output
    end

    return true, output
end

-- public
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
end

return {
    notifyPlayer = notifyPlayer,
    initialize = initializeServer,
}
