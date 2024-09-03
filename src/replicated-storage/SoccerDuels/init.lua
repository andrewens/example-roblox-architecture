-- dependency
local RunService = game:GetService("RunService")

--[[ CLIENT ]]
if RunService:IsClient() then
	local AssetDependencies = require(script.AssetDependencies)
	local Config = require(script.Config)
	local Enums = require(script.Enums)
	local Maid = require(script.Maid)
	local SoccerDuelsClient = require(script.SoccerDuelsClient)

	-- public
	local function initializeSoccerDuelsClient()
		Enums.initialize()
		Maid.initialize()
		SoccerDuelsClient.initialize()
	end

	return {
		-- client
		newClient = SoccerDuelsClient.new,

		-- config
		getConstant = Config.getConstant,

		-- assets
		getAsset = AssetDependencies.getAsset,
		getExpectedAssets = AssetDependencies.getExpectedAssets,

		-- SoccerDuels
		initialize = initializeSoccerDuelsClient,
	}
end

--[[ SERVER ]]
local AssetDependencies = require(script.AssetDependencies)
local Config = require(script.Config)
local Enums = require(script.Enums)
local Maid = require(script.Maid)
local SoccerDuelsClient = require(script.SoccerDuelsClient)
local SoccerDuelsServer = require(script.SoccerDuelsServer)
local Utility = require(script.Utility)

-- public
local function initializeSoccerDuels()
	Utility.organizeDependencies()
	Enums.initialize()
	Maid.initialize()
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
	getExpectedAssets = AssetDependencies.getExpectedAssets,

	-- SoccerDuels
	initialize = initializeSoccerDuels,
}
