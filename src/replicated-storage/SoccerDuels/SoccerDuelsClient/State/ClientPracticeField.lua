-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Network = require(SoccerDuelsModule.Network)

-- public / Client class methods
local function clientTouchedPracticeFieldTeleportPart(self, TouchingPart)
	local PracticeFieldTeleportPart = Assets.getExpectedAsset("PracticeFieldTeleportPart")
	if not (TouchingPart == PracticeFieldTeleportPart) then
		return
	end

    Network.fireServer("PlayerRequestToJoinPracticeField", self.Player)
end

return {
	touchedPracticeFieldTeleportPart = clientTouchedPracticeFieldTeleportPart,
}
