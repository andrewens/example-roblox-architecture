-- dependency
local AssetDependencies = require(script.AssetDependencies)
local SoccerDuelsClient = require(script.SoccerDuelsClient)

-- public
local function initializeSoccerDuels() end

return {
    -- client
    newClient = SoccerDuelsClient.new,

    -- assets
	getAsset = AssetDependencies.getAsset,
    getExpectedAssets = AssetDependencies.getExpectedAssets,

    -- SoccerDuels
	initialize = initializeSoccerDuels,
}
