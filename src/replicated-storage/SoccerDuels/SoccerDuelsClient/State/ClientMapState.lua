-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)

-- const
local LOADING_MAP_ENUM = Enums.getEnum("MapState", "Loading")

-- protected / Network methods
local function playerConnectedMapChanged(self, Player, mapEnum, teamIndex)
    self._PlayerConnectedMapEnum[Player] = mapEnum
    self._PlayerTeamIndex[Player] = teamIndex
end
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
local function getClientConnectedMapName(self, Player)
    local mapEnum = self._PlayerConnectedMapEnum[Player or self.Player]
    if mapEnum then
        return Enums.enumToName("Map", mapEnum)
    end
end
local function initializeClientMapState(self)
	self._Maid:GiveTask(Network.onClientEventConnect("MapStateChanged", self.Player, function(...)
		playerConnectedMapStateChanged(self, ...)
	end))
    self._Maid:GiveTask(Network.onClientEventConnect("PlayerConnectedMapChanged", self.Player, function(...)
        playerConnectedMapChanged(self, ...)
    end))
end

return {
    getClientConnectedMapName= getClientConnectedMapName,

	initialize = initializeClientMapState,
}
