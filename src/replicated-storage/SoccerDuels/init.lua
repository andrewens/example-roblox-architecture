-- dependency
local RunService = game:GetService("RunService")

--[[ CLIENT ]]
if RunService:IsClient() then
	local Config = require(script.Config) -- needs to be required first!
	local SoccerDuelsClient = require(script.SoccerDuelsClient)

	-- public
	local function initializeSoccerDuelsClient()
		SoccerDuelsClient.initialize()
	end

	return {
		-- client
		newClient = SoccerDuelsClient.new,

		-- config
		getConstant = Config.getConstant,

		-- SoccerDuels client
		initialize = initializeSoccerDuelsClient,
	}
end

--[[ SERVER ]]
local Config = require(script.Config) -- needs to be required first!
local AssetDependencies = require(script.AssetDependencies)
local PlayerDocument = require(script.PlayerDocument)
local SoccerDuelsClient = require(script.SoccerDuelsClient)
local SoccerDuelsServer = require(script.SoccerDuelsServer)
local Utility = require(script.Utility)

-- public
local function initializeSoccerDuels()
	Utility.organizeDependencies()
	SoccerDuelsServer.initialize()
	SoccerDuelsClient.initialize()
end

return {
	-- database
	newPlayerDocument = PlayerDocument.new,
	getAvailableDataStoreRequests = SoccerDuelsServer.getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = SoccerDuelsServer.getPlayerSaveDataAsync,
	savePlayerDataAsync = SoccerDuelsServer.savePlayerDataAsync,

	-- config
	getConstant = Config.getConstant,

	-- assets
	getAsset = AssetDependencies.getAsset,
	getExpectedAsset = AssetDependencies.getExpectedAsset,
	getExpectedAssets = AssetDependencies.getExpectedAssets,

	-- SoccerDuels client
	newClient = SoccerDuelsClient.new,

	-- SoccerDuels server
	getLoadedPlayers = SoccerDuelsServer.getLoadedPlayers,
	disconnectPlayer = SoccerDuelsServer.disconnectPlayer,
	disconnectAllPlayers = SoccerDuelsServer.disconnectAllPlayers,
	getCachedPlayerSaveData = SoccerDuelsServer.getCachedPlayerSaveData,
	notifyPlayer = SoccerDuelsServer.notifyPlayer,

	initialize = initializeSoccerDuels,

	-- testing API
	wait = SoccerDuelsServer.wait,
	setTestingVariable = SoccerDuelsServer.setTestingVariable,
	getTestingVariable = SoccerDuelsServer.getTestingVariable,
	resetTestingVariables = SoccerDuelsServer.resetTestingVariables,
}
