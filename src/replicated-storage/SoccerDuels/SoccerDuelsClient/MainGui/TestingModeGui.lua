-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)

-- public
local function initializeTestingModeGui(Client, MainGui)
    local TestingModeLabel = Assets.getExpectedAsset("TestingModeLabel", "MainGui", MainGui)
    TestingModeLabel.Visible = Config.getConstant("TestingMode")
end

return {
    new = initializeTestingModeGui,
}
