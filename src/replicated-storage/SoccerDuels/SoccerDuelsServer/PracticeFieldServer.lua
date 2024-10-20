-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)

local SoccerDuelsServer -- required in initialize
local MapsServer = require(SoccerDuelsServerModule.MapsServer)

local PracticeFieldTeleportPart = Assets.getExpectedAsset("PracticeFieldTeleportPart")

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

-- var
local practiceFieldMapId

-- protected / Network methods
local function onClientRequestToJoinPracticeField(Player)
    if not SoccerDuelsServer.playerIsInLobby(Player) then
        return
    end

    if practiceFieldMapId == nil or MapsServer.getMapInstanceFolder(practiceFieldMapId) == nil then
        practiceFieldMapId = MapsServer.newMapInstance("PracticeField", {
            MatchCycleEnabled = false
        })
    end

    MapsServer.connectPlayerToMapInstance(Player, practiceFieldMapId, 1)
end

-- public
local function initializePracticeFieldServer()
	SoccerDuelsServer = require(SoccerDuelsServerModule)

	PracticeFieldTeleportPart.Anchored = true
	PracticeFieldTeleportPart.CanCollide = false
	PracticeFieldTeleportPart.CanTouch = true
	PracticeFieldTeleportPart.Transparency = if TESTING_MODE then 0.8 else 1

	Network.onServerEventConnect("PlayerRequestToJoinPracticeField", onClientRequestToJoinPracticeField)
    Network.onServerEventConnect("PlayerDisconnectFromAllMapInstances", MapsServer.disconnectPlayerFromAllMapInstances)
end

return {
	initialize = initializePracticeFieldServer,
}
