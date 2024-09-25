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
local Time = require(script.Time)
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
	getExpectedAssets = AssetDependencies.getExpectedAssets,
	getExpectedAsset = AssetDependencies.getExpectedAsset,
	getAsset = AssetDependencies.getAsset,

	-- SoccerDuels client
	newClient = SoccerDuelsClient.new,

	-- database
	getAvailableDataStoreRequests = SoccerDuelsServer.getAvailableDataStoreRequests,
	getPlayerSaveDataAsync = SoccerDuelsServer.getPlayerSaveDataAsync,
	savePlayerDataAsync = SoccerDuelsServer.savePlayerDataAsync,
	newPlayerDocument = PlayerDocument.new,

	-- match joining pads
	teleportPlayerToLobbySpawnLocation = SoccerDuelsServer.teleportPlayerToLobbySpawnLocation,
	teleportPlayerToMatchPad = SoccerDuelsServer.teleportPlayerToMatchPad,

	getPlayerConnectedMatchPadName = SoccerDuelsServer.getPlayerConnectedMatchPadName,
	getPlayerConnectedMatchPadTeam = SoccerDuelsServer.getPlayerConnectedMatchPadTeam,
	getMatchPadTeamPlayers = SoccerDuelsServer.getMatchPadTeamPlayers,
	getMatchJoiningPads = SoccerDuelsServer.getMatchJoiningPads,
	matchPadTimerTick = SoccerDuelsServer.matchPadTimerTick,
	getMatchPadState = SoccerDuelsServer.getMatchPadState,

	-- notify players
	notifyPlayer = SoccerDuelsServer.notifyPlayer,

	-- SoccerDuels server
	updateCachedPlayerSaveData = SoccerDuelsServer.updateCachedPlayerSaveData,
	getCachedPlayerSaveData = SoccerDuelsServer.getCachedPlayerSaveData,
	disconnectAllPlayers = SoccerDuelsServer.disconnectAllPlayers,
	playerDataIsSaved = SoccerDuelsServer.playerDataIsSaved,
	saveAllPlayerData = SoccerDuelsServer.saveAllPlayerData,
	getLoadedPlayers = SoccerDuelsServer.getLoadedPlayers,
	disconnectPlayer = SoccerDuelsServer.disconnectPlayer,

	initialize = initializeSoccerDuels,

	-- time
	getUnixTimestampMilliseconds = Time.getUnixTimestampMilliseconds,
	getUnixTimestamp = Time.getUnixTimestamp,

	-- testing API
	addExtraSecondsForTesting = SoccerDuelsServer.addExtraSecondsForTesting,
	resetTestingVariables = SoccerDuelsServer.resetTestingVariables,
	setTestingVariable = SoccerDuelsServer.setTestingVariable,
	getTestingVariable = SoccerDuelsServer.getTestingVariable,
	wait = SoccerDuelsServer.wait,
}
