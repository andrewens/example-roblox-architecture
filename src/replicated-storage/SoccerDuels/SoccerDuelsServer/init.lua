-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local RemoteEvents = require(SoccerDuelsModule.RemoteEvents)

-- protected / network methods
local function getPlayerSaveData(Player)
    print("getPlayerSaveData", Player)

    return true, {}
end

-- public
local function initializeServer()
    RemoteEvents.GetPlayerSaveData.OnServerInvoke = getPlayerSaveData
end

return {
    initialize = initializeServer,
}
