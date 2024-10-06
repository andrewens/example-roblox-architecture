-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)
local Time = require(SoccerDuelsModule.Time)

local TestingVariables = require(SoccerDuelsServerModule.TestingVariables)

-- const
local PING_CHECK_POLL_RATE_SECONDS = Config.getConstant("PingCheckPollRateSeconds")
local INITIAL_PLAYER_PING_VALUE_MILLISECONDS = Config.getConstant("InitialPlayerPingValueMilliseconds")
local MAX_PING_TIMEOUT_SECONDS = Config.getConstant("MaxPingTimeoutSeconds")

-- var
local PlayerPingSentTimestamp = {} -- Player --> int unixTimestampMilliseconds
local PlayerPing = {} -- Player --> int lastPingDurationMilliseconds

-- private
local function cachePlayerPing(Player, pingMilliseconds)
	PlayerPingSentTimestamp[Player] = nil
	PlayerPing[Player] = pingMilliseconds
	Network.fireAllClients("ReplicatePlayerPing", Player, pingMilliseconds)
end
local function pingPlayer(Player)
	-- there can only be one ping at a time
	if PlayerPingSentTimestamp[Player] then
		-- check if player has taken too long to get back to us
		local timeSinceLastPingMilliseconds = Time.getUnixTimestampMilliseconds() - PlayerPingSentTimestamp[Player]
		local maxPingMilliseconds = 1E3 * MAX_PING_TIMEOUT_SECONDS

		if timeSinceLastPingMilliseconds >= maxPingMilliseconds then
			cachePlayerPing(Player, maxPingMilliseconds)
		end

		return
	end

	PlayerPingSentTimestamp[Player] = Time.getUnixTimestampMilliseconds()

	if TestingVariables.getVariable("ExtraLoadTime") > 0 then
		task.wait(TestingVariables.getVariable("ExtraLoadTime"))
	end

	Network.fireClient("PingPlayer", Player, PlayerPingSentTimestamp[Player])
end
local function pingAllPlayers()
	for Player, _ in PlayerPing do
		pingPlayer(Player)
	end
end

-- protected / Network methods
local function onPlayerReturnPing(Player, pingSentTimestamp)
	if PlayerPingSentTimestamp[Player] == nil then
		return -- player might have disconnected or their ping timed out
	end

	if PlayerPingSentTimestamp[Player] ~= pingSentTimestamp then
		return -- they're returning a different ping (e.g. if a ping timed out)
	end

	if TestingVariables.getVariable("ExtraLoadTime") > 0 then
		task.wait(TestingVariables.getVariable("ExtraLoadTime"))
	end

	cachePlayerPing(Player, Time.getUnixTimestampMilliseconds() - PlayerPingSentTimestamp[Player])
end

-- public
local function getCachedPlayerPingMilliseconds(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return PlayerPing[Player]
end
local function pingPlayerAsync(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	pingPlayer(Player)

	while PlayerPingSentTimestamp[Player] do
		task.wait()
	end

	return PlayerPing[Player]
end
local function playerDataLoaded(Player)
	PlayerPing[Player] = INITIAL_PLAYER_PING_VALUE_MILLISECONDS
end
local function initializePlayerPingServer()
	Network.onServerEventConnect("PingPlayer", onPlayerReturnPing)
	Utility.runServiceSteppedConnect(PING_CHECK_POLL_RATE_SECONDS, pingAllPlayers)
end

return {
	getPlayerPingMilliseconds = getCachedPlayerPingMilliseconds,
	pingPlayerAsync = pingPlayerAsync,

	initialize = initializePlayerPingServer,
	disconnectPlayer = cachePlayerPing, -- yes, cachePlayerPing() is still private. it just happens that we don't need an extra function for disconnectPlayer()
	playerDataLoaded = playerDataLoaded,
}
