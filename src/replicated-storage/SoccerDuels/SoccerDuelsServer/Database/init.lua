-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)
local DataStoreWrapper = require(script.DataStoreWrapper)

local PlayerDataStore = DataStoreWrapper.getDataStore("PlayerData")

-- const
local NUM_RETRIES = Config.getConstant("DatabaseQueryRetries")
local DATABASE_RETRY_WAIT = Config.getConstant("DatabaseRetryWaitSeconds")

-- private
local function getPlayerDatabaseKey(Player)
    return `User_{Player.UserId}`
end
local function newPlayerSaveData()
    return {
        Level = 0,
        WinStreak = 0,
        Settings = {},
    }
end

-- public
local function loadPlayerSaveDataAsync(Player)
    if not Utility.isA(Player, "Player") then
        error(`{Player} is not a Player!`)
    end

    local key = getPlayerDatabaseKey(Player)

    local s, output
    for i = 1, NUM_RETRIES do
        s, output = pcall(PlayerDataStore.GetAsync, PlayerDataStore, key)
        if s then
            if output == nil then
                output = newPlayerSaveData()
            end

            break
        end

        task.wait(DATABASE_RETRY_WAIT)
    end

    return s, output
end
local function initializeDatabaseWrapper()

end

return {
    loadPlayerSaveDataAsync = loadPlayerSaveDataAsync,
    initialize = initializeDatabaseWrapper,
}
