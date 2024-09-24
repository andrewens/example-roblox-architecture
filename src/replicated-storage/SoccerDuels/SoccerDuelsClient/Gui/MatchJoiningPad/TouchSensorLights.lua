-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Enums = require(SoccerDuelsModule.Enums)

local Sounds = require(SoccerDuelsClientModule.Sounds)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- public / Client class methods
local function destroyTouchSensorLights(self) end
local function newTouchSensorLights(self)
	self:OnLobbyCharacterTouchedMatchPadConnect(function(matchPadName, teamIndex)
		Sounds.playSound(self, "StepOnMatchJoiningPadSound")
		UIAnimations.flashNeonPart(self, Assets.getExpectedAsset(`{matchPadName} Pad{teamIndex}Light`))
	end)
end

return {
	new = newTouchSensorLights,
	destroy = destroyTouchSensorLights,
}
