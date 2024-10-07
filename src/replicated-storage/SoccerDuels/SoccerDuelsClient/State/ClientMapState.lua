-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)

-- const
local LOADING_MAP_ENUM = Enums.getEnum("MapState", "Loading")

-- protected / Network methods
local function playerConnectedMapStateChanged(self, mapStateEnum)
    if mapStateEnum == nil then
        ClientUserInterfaceMode.setClientUserInterfaceMode(self, "Lobby")
        return
    end

    if mapStateEnum == LOADING_MAP_ENUM then
        ClientUserInterfaceMode.setClientUserInterfaceMode(self, "LoadingMap")
        return
    end

    local mapStateName = Enums.enumToName("MapState", mapStateEnum)
    ClientUserInterfaceMode.setClientUserInterfaceMode(self, mapStateName)
end

-- public
local function initializeClientMapState(self)
	self._Maid:GiveTask(Network.onClientEventConnect("MapStateChanged", self.Player, function(...)
		playerConnectedMapStateChanged(self, ...)
	end))
end

return {
	initialize = initializeClientMapState,
}
