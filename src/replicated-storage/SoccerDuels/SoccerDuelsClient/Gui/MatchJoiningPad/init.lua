-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function destroyMatchJoiningPadGui(self) end
local function newMatchJoiningPadGui(self)
	local MatchJoiningPadGui = Assets.getExpectedAsset("MatchJoiningPadGui", "MainGui", self._MainGui)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		MatchJoiningPadGui.Visible = (userInterfaceMode == "MatchJoiningPad")
	end)
end

return {
	destroy = destroyMatchJoiningPadGui,
	new = newMatchJoiningPadGui,
}
