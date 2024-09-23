-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)

-- public / Client class methods
local function destroyTestingModeGui(self) end
local function newTestingModeGui(self)
	local TestingModeLabel = Assets.getExpectedAsset("TestingModeLabel", "MainGui", self._MainGui)
	TestingModeLabel.Visible = Config.getConstant("TestingMode")
end

return {
	destroy = destroyTestingModeGui,
	new = newTestingModeGui,
}
