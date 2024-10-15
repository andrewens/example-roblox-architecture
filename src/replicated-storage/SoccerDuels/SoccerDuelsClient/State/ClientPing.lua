-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local GOOD_PING_THRESHOLD_MILLISECONDS = Config.getConstant("PingQualityThresholdMilliseconds", "Good")
local OKAY_PING_THRESHOLD_MILLISECONSD = Config.getConstant("PingQualityThresholdMilliseconds", "Okay")
local PLACE_HOLDER_PING_QUALITY = Config.getConstant("PlaceholderPingQuality")

-- private
local function getPingQuality(playerPingMilliseconds)
	if playerPingMilliseconds == nil then
		return PLACE_HOLDER_PING_QUALITY
	end

	if playerPingMilliseconds <= GOOD_PING_THRESHOLD_MILLISECONDS then
		return "Good"
	elseif playerPingMilliseconds <= OKAY_PING_THRESHOLD_MILLISECONSD then
		return "Okay"
	end

	return "Bad"
end

-- protected / Network methods
local function onPingPlayer(self, pingSentTimestamp)
	Network.fireServer("PingPlayer", self.Player, pingSentTimestamp)
end
local function playerPingReplicated(self, Player, pingMilliseconds)
	local prevPing = self._PlayerPingMilliseconds[Player]
	local newPingQuality = getPingQuality(pingMilliseconds)

	self._PlayerPingMilliseconds[Player] = pingMilliseconds

	if prevPing == nil or getPingQuality(prevPing) ~= newPingQuality then
		for callback, _ in self._PlayerPingQualityChangedCallbacks do
			callback(Player, newPingQuality)
		end
	end
end

-- public
local function onPlayerPingQualityChangeConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for Player, playerPingMilliseconds in self._PlayerPingMilliseconds do
		callback(Player, getPingQuality(playerPingMilliseconds))
	end

	self._PlayerPingQualityChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerPingQualityChangedCallbacks[callback] = nil
		end,
	}
end
local function getPlayerPingQuality(self, Player)
	Player = Player or self.Player

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return getPingQuality(self._PlayerPingMilliseconds[Player])
end
local function getCachedPlayerPingMilliseconds(self, Player)
	Player = Player or self.Player

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return self._PlayerPingMilliseconds[Player]
end
local function initializeClientPing(self)
	self.Maid:GiveTask(Network.onClientEventConnect("PingPlayer", self.Player, function(...)
		onPingPlayer(self, ...)
	end))
	self.Maid:GiveTask(Network.onClientEventConnect("ReplicatePlayerPing", self.Player, function(...)
		playerPingReplicated(self, ...)
	end))
end

return {
	onPlayerPingQualityChangeConnect = onPlayerPingQualityChangeConnect,
	getPlayerPingMilliseconds = getCachedPlayerPingMilliseconds,
	getPlayerPingQuality = getPlayerPingQuality,

	initialize = initializeClientPing,
}
