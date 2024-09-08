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
	-- client
	newClient = SoccerDuelsClient.new,

	-- database
	newPlayerDocument = PlayerDocument.new,

	-- config
	getConstant = Config.getConstant,

	-- assets
	getAsset = AssetDependencies.getAsset,
	getExpectedAsset = AssetDependencies.getExpectedAsset,
	getExpectedAssets = AssetDependencies.getExpectedAssets,

	-- SoccerDuels server
	getPlayerSaveData = SoccerDuelsServer.getPlayerSaveData,
	notifyPlayer = SoccerDuelsServer.notifyPlayer,
	initialize = initializeSoccerDuels,

	-- testing API
	wait = SoccerDuelsServer.wait,
	setTestingVariable = SoccerDuelsServer.setTestingVariable,
	getTestingVariable = SoccerDuelsServer.getTestingVariable,
	resetTestingVariables = SoccerDuelsServer.resetTestingVariables,
}
