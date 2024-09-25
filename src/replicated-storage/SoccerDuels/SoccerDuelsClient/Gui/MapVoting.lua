-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)

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

    MapButtonTemplate.Parent = nil
    PlayerIconTemplate.Parent = nil

    for _, MapVotingMapButton in MapContainer:GetChildren() do
        if not MapVotingMapButton:IsA(MapButtonTemplate.ClassName) then
            continue
        end

        MapVotingMapButton:Destroy()
    end

    for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
        local MapButton = MapButtonTemplate:Clone()
        MapButton.LayoutOrder = mapEnum
        MapButton.Name = mapName
        MapButton.Image = Config.getConstant("MapThumbnailImages", mapName)
        MapButton.Parent = MapContainer

        MapButton.Activated:Connect(function()
            print("Vote", mapName)
        end)
    end
end

return {
	destroy = destroyMapVotingGui,
	new = newMapVotingGui,
}
