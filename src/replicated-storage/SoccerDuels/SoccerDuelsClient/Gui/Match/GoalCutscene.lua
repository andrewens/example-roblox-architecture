-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local AvatarHeadshotImages = require(SoccerDuelsClientModule.AvatarHeadshotImages)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const


-- public / Client class methods
local function newGoalCutsceneGui(self)
    local GoalCutsceneGui = Assets.getExpectedAsset("GoalCutsceneGui", "MainGui", self.MainGui)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
        GoalCutsceneGui.Visible = (userInterfaceMode == "GoalCutscene")
    end)

    GoalCutsceneGui.Visible = false
end

return {
	new = newGoalCutsceneGui,
}
