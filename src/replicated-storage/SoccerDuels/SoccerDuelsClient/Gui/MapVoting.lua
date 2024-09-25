-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public
local function destroyMapVotingGui(self) end
local function newMapVotingGui(self)
	local MapVotingModal = Assets.getExpectedAsset("MapVotingModal", "MainGui", self._MainGui)
	local MapContainer = Assets.getExpectedAsset("MapVotingMapContainer", "MapVotingModal", MapVotingModal)
	local MapButtonTemplate =
		Assets.getExpectedAsset("MapVotingMapButton", "MapVotingMapContainer", MapContainer)
	local PlayerIconTemplate = Assets.getExpectedAsset("MapVotingPlayerIcon", "MapVotingMapButton", MapButtonTemplate)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		MapVotingModal.Visible = userInterfaceMode == "MapVoting"

		if not MapVotingModal.Visible then
			return
		end

		-- TODO ...
	end)

	MapVotingModal.Visible = false
end

return {
	destroy = destroyMapVotingGui,
	new = newMapVotingGui,
}
