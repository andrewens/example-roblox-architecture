-- dependency
local DataStoreService = game:GetService("DataStoreService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

-- public / MockDataStore class methods
local function mockDataStoreGetAsync(self, key)
    return nil
end
local function newMockDataStore(dataStoreName)
    -- properties
    local self = {}
    self.Name = dataStoreName

    -- methods
    self.GetAsync = mockDataStoreGetAsync

    return self
end

-- public
local function getDataStore(dataStoreName)
    if not (typeof(dataStoreName) == "string") then
        error(`{dataStoreName} is not a string!`)
    end

    if TESTING_MODE then
        return newMockDataStore(dataStoreName)
    end

    return DataStoreService:GetDataStore(dataStoreName)
end

return {
    getDataStore = getDataStore,
}
