-- dependency
local RunService = game:GetService("RunService")

--[[ CLIENT ]]
if RunService:IsClient() then
	local Config = require(script.Config) -- needs to be required first!
	local SoccerDuelsClient = require(script.SoccerDuelsClient)
	local Network = require(script.Network)

	-- public
	local function initializeSoccerDuelsClient()
		Network.initialize()
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
local Network = require(script.Network)

-- public
local function initializeSoccerDuels()
	Utility.organizeDependencies()
	Network.initialize()
	SoccerDuelsServer.initialize()
	SoccerDuelsClient.initialize()
end

return {
	-- config
	getConstant = Config.getConstant,

	-- assets
	getAsset = AssetDependencies.getAsset,
	getExpectedAsset = AssetDependencies.getExpectedAsset,
	getExpectedAssets = AssetDependencies.getExpectedAssets,

	-- SoccerDuels client
	newClient = SoccerDuelsClient.new,

	-- database
	newPlayerDocument = PlayerDocument.new,
	getAvailableDataStoreRequests = SoccerDuelsServer.getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = SoccerDuelsServer.getPlayerSaveDataAsync,
	savePlayerDataAsync = SoccerDuelsServer.savePlayerDataAsync,

	-- match joining pads
	getMatchJoiningPads = SoccerDuelsServer.getMatchJoiningPads,
	teleportPlayerToMatchPad = SoccerDuelsServer.teleportPlayerToMatchPad,

	-- notify players
	notifyPlayer = SoccerDuelsServer.notifyPlayer,

	-- SoccerDuels server
	getLoadedPlayers = SoccerDuelsServer.getLoadedPlayers,
	disconnectPlayer = SoccerDuelsServer.disconnectPlayer,
	disconnectAllPlayers = SoccerDuelsServer.disconnectAllPlayers,
	saveAllPlayerData = SoccerDuelsServer.saveAllPlayerData,
	playerDataIsSaved = SoccerDuelsServer.playerDataIsSaved,
	updateCachedPlayerSaveData = SoccerDuelsServer.updateCachedPlayerSaveData,
	getCachedPlayerSaveData = SoccerDuelsServer.getCachedPlayerSaveData,

	initialize = initializeSoccerDuels,

	-- testing API
	wait = SoccerDuelsServer.wait,
	setTestingVariable = SoccerDuelsServer.setTestingVariable,
	getTestingVariable = SoccerDuelsServer.getTestingVariable,
	resetTestingVariables = SoccerDuelsServer.resetTestingVariables,
}
