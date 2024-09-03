-- dependency
local AssetDependencies = require(script.AssetDependencies)
local Enums = require(script.Enums)
local SoccerDuelsClient = require(script.SoccerDuelsClient)
local Utility = require(script.Utility)

-- public
local function initializeSoccerDuels()
    Utility.moveStarterGuiToReplicatedStorage()
    Enums.initialize()
    SoccerDuelsClient.initialize()
end

return {
    -- client
    newClient = SoccerDuelsClient.new,

    -- assets
	getAsset = AssetDependencies.getAsset,
    getExpectedAssets = AssetDependencies.getExpectedAssets,

    -- SoccerDuels
	initialize = initializeSoccerDuels,
}
