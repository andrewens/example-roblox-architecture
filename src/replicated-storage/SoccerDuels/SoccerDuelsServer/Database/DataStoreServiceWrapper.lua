-- dependency
local DataStoreService = game:GetService("DataStoreService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local TestingVariables = require(SoccerDuelsServerModule.TestingVariables)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

-- public / MockDataStore class methods
-- TODO put this in its own module
local function mockDataStoreSetAsync(self, key, value)
	if TestingVariables.getVariable("NetworkAutoFail") then
		error(`Testing automatic network failure`)
	end
	if TestingVariables.getVariable("SimulateDataStoreBudget") then
		if TestingVariables.getVariable("DataStoreRequestBudget/Save") <= 0 then
			error(`Too many DataStore SetAsync requests!`)
		end
		TestingVariables.decrementVariable("DataStoreRequestBudget/Save")
	end

	-- TODO maybe think about other datastore constraints throwing errors here

	self._Data[key] = value
end
local function mockDataStoreGetAsync(self, key)
	if TestingVariables.getVariable("NetworkAutoFail") then
		error(`Testing automatic network failure`)
	end
	if TestingVariables.getVariable("SimulateDataStoreBudget") then
		if TestingVariables.getVariable("DataStoreRequestBudget/Load") <= 0 then
			error(`Too many DataStore GetAsync requests!`)
		end
		TestingVariables.decrementVariable("DataStoreRequestBudget/Load")
	end

	return self._Data[key]
end
local function newMockDataStore(dataStoreName)
	-- properties
	local self = {}
	self.Name = dataStoreName
	self._Data = {} -- key --> value

	-- methods
	self.GetAsync = mockDataStoreGetAsync
	self.SetAsync = mockDataStoreSetAsync

	return self
end

-- public
local function getRequestBudgetForRequestType(self, requestTypeEnum)
	if TESTING_MODE and TestingVariables.getVariable("SimulateDataStoreBudget") then
		local requestTypeName = Enums.enumToName("DataStoreRequestType", requestTypeEnum)
		return TestingVariables.getVariable("DataStoreRequestBudget/" .. requestTypeName)
	end

	return DataStoreService:GetRequestBudgetForRequestType(requestTypeEnum - 1)
end
local function getDataStore(self, dataStoreName)
	if not (typeof(dataStoreName) == "string") then
		error(`{dataStoreName} is not a string!`)
	end

	if TESTING_MODE then
		return newMockDataStore(dataStoreName)
	end

	return DataStoreService:GetDataStore(dataStoreName)
end

return {
	GetDataStore = getDataStore,
	GetRequestBudgetForRequestType = getRequestBudgetForRequestType,
}
