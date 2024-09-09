-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)
local PlayerDocument = require(SoccerDuelsModule.PlayerDocument)

local TestingVariables = require(SoccerDuelsServerModule.TestingVariables)
local DataStoreServiceWrapper = require(script.DataStoreServiceWrapper)

local PlayerDataStore = DataStoreServiceWrapper:GetDataStore("PlayerData")

-- const
local NUM_RETRIES = Config.getConstant("DatabaseQueryRetries")
local DATABASE_RETRY_WAIT = Config.getConstant("DatabaseRetryWaitSeconds")
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")

-- private
local function getPlayerDatabaseKey(Player)
	return `User_{Player.UserId}`
end
local function newPlayerSaveData()
	return Utility.tableDeepCopy(DEFAULT_PLAYER_SAVE_DATA)
end

-- public
local function getAvailableDataStoreRequests(requestType)
	if not (typeof(requestType) == "string") then
		error(`{requestType} is not a string!`)
	end

	local requestTypeEnum = Enums.getEnum("DataStoreRequestType", requestType)
	if requestTypeEnum == nil then
		error(`{requestType} is not a DataStoreRequestType Enum!`)
	end

	return DataStoreServiceWrapper:GetRequestBudgetForRequestType(requestTypeEnum)
end
local function savePlayerDataAsync(Player, PlayerSaveData)
	if not Utility.isA(Player, "Player") then
		error(`{Player} isn't a Player!`)
	end
	if not PlayerDocument.isAPlayerDocument(PlayerSaveData) then
		error(`{PlayerSaveData} isn't a PlayerDocument!`)
	end

	-- wait until we have request budget
	while getAvailableDataStoreRequests("Save") <= 0 do -- TODO not sure if this will work at scale
		task.wait()
	end

	local key = getPlayerDatabaseKey(Player)
	local playerSaveDataJson = PlayerSaveData:ToJson()

	local s, output
	for i = 1, NUM_RETRIES do
		s, output = pcall(PlayerDataStore.SetAsync, PlayerDataStore, key, playerSaveDataJson)
		if s then
			break
		end

		TestingVariables.wait(DATABASE_RETRY_WAIT)
	end

	if not s then
		error(output)
	end
end
local function getPlayerSaveDataAsync(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	-- wait until we have request budget
	while getAvailableDataStoreRequests("Load") <= 0 do -- TODO not sure if this will work at scale
		task.wait()
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

		TestingVariables.wait(DATABASE_RETRY_WAIT)
	end

	if not s then
		error(output)
	end

	return PlayerDocument.new(output)
end
local function initializeDatabaseWrapper() end

return {
	savePlayerDataAsync = savePlayerDataAsync,
	getAvailableDataStoreRequests = getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = getPlayerSaveDataAsync,
	initialize = initializeDatabaseWrapper,
}
