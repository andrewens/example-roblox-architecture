-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function newGameOverGui(self)
    local GameOverGui = Assets.getExpectedAsset("GameOverGui", "MainGui", self.MainGui)

    self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
        GameOverGui.Visible = (userInterfaceMode == "GameOver")
    end)

    GameOverGui.Visible = false
end

return {
    new = newGameOverGui,
}
