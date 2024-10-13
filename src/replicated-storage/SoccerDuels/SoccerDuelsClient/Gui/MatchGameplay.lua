-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Maid = require(SoccerDuelsModule.Maid)

local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const
local GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE = {
	["MatchCountdown"] = true,
	["MatchGameplay"] = true,
	["Gameplay"] = true,
}

-- public / Client class methods
local function newMatchLoadingScreenGui(self)
	local GameplayGui = Assets.getExpectedAsset("MatchGameplayGui", "MainGui", self._MainGui)
	local MatchCounterTextLabel = Assets.getExpectedAsset("MatchCountdownTimerLabel", "MatchGameplayGui", GameplayGui)

	GameplayGui.Visible = false

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		GameplayGui.Visible = GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE[userInterfaceMode] or false
		MatchCounterTextLabel.Visible = userInterfaceMode == "MatchCountdown"
	end)
end

return {
	new = newMatchLoadingScreenGui,
}
