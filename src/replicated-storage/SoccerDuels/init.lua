-- dependency
local AssetDependencies = require(script.AssetDependencies)
local Enums = require(script.Enums)
local SoccerDuelsClient = require(script.SoccerDuelsClient)

-- public
local function initializeSoccerDuels()
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
