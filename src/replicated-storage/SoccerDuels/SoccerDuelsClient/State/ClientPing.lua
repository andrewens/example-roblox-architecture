-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local GOOD_PING_THRESHOLD_MILLISECONDS = Config.getConstant("PingQualityThresholdMilliseconds", "Good")
local OKAY_PING_THRESHOLD_MILLISECONSD = Config.getConstant("PingQualityThresholdMilliseconds", "Okay")
local PLACE_HOLDER_PING_QUALITY = Config.getConstant("PlaceholderPingQuality")

-- protected / Network methods
local function onPingPlayer(self, pingSentTimestamp)
	Network.fireServer("PingPlayer", self.Player, pingSentTimestamp)
end
local function playerPingReplicated(self, Player, pingMilliseconds)
	self._PlayerPingMilliseconds[Player] = pingMilliseconds
end

-- public
local function getPlayerPingQuality(self, Player)
    Player = Player or self.Player

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

    local playerPingMilliseconds = self._PlayerPingMilliseconds[Player]
    if playerPingMilliseconds == nil then
		return PLACE_HOLDER_PING_QUALITY
	end

	if playerPingMilliseconds <= GOOD_PING_THRESHOLD_MILLISECONDS then
		return "Good"
	end

	if playerPingMilliseconds <= OKAY_PING_THRESHOLD_MILLISECONSD then
		return "Okay"
	end

	return "Bad"
end
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
	getPlayerPingQuality = getPlayerPingQuality,

	initialize = initializeClientPing,
}
