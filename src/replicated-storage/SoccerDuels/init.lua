-- dependency
local RunService = game:GetService("RunService")

--[[ CLIENT ]]
if RunService:IsClient() then
	local SoccerDuelsClient = require(script.SoccerDuelsClient)

	-- public
	local function initializeSoccerDuelsClient()
		SoccerDuelsClient.initialize()
	end

	return {
		-- client
		newClient = SoccerDuelsClient.new,

		-- SoccerDuels client
		initialize = initializeSoccerDuelsClient,
	}
end

--[[ SERVER ]]
local AssetDependencies = require(script.AssetDependencies)
local Config = require(script.Config)
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

	-- config
	getConstant = Config.getConstant,

	-- assets
	getAsset = AssetDependencies.getAsset,
	getExpectedAsset = AssetDependencies.getExpectedAsset,
	getExpectedAssets = AssetDependencies.getExpectedAssets,

	-- SoccerDuels server
	notifyPlayer = SoccerDuelsServer.notifyPlayer,
	initialize = initializeSoccerDuels,
}
