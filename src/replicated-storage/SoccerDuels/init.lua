-- dependency
local AssetDependencies = require(script.AssetDependencies)

-- public
local function initializeSoccerDuels() end

return {
    -- assets
	getAsset = AssetDependencies.getAsset,
    getExpectedAssets = AssetDependencies.getExpectedAssets,

    -- SoccerDuels
	initialize = initializeSoccerDuels,
}
