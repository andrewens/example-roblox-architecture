-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- protected / Network methods
local function onPingPlayer(self, pingSentTimestamp)
    Network.fireServer("PingPlayer", self.Player, pingSentTimestamp)
end
local function playerPingReplicated(self, Player, pingMilliseconds)
    self._PlayerPingMilliseconds[Player] = pingMilliseconds
end

-- public
local function getCachedPlayerPingMilliseconds(self, Player)
    Player = Player or self.Player

    if not Utility.isA(Player, "Player") then
        error(`{Player} is not a Player!`)
    end

    return self._PlayerPingMilliseconds[Player]
end
local function initializeClientPing(self)
	self._Maid:GiveTask(Network.onClientEventConnect("PingPlayer", self.Player, function(...)
		onPingPlayer(self, ...)
	end))
    self._Maid:GiveTask(Network.onClientEventConnect("ReplicatePlayerPing", self.Player, function(...)
        playerPingReplicated(self, ...)
    end))
end

return {
    getPlayerPingMilliseconds = getCachedPlayerPingMilliseconds,
	initialize = initializeClientPing,
}
