-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)
local Database = require(script.Database)

-- protected / network methods
local function getPlayerSaveData(Player)
    local s, output = Database.loadPlayerSaveDataAsync(Player)
    if not s then
        Player:Kick(`Failed to load your saved data: {output}`)

        return false, output
    end

    return true, output
end

-- public
local function initializeServer()
    Database.initialize()

    RemoteEvents.GetPlayerSaveData.OnServerInvoke = getPlayerSaveData
end

return {
    initialize = initializeServer,
}
