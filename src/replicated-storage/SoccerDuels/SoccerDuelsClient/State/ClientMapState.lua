-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

local ClientModalState = require(SoccerDuelsClientStateFolder.ClientModalState)
local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)

-- const
local LOADING_MAP_ENUM = Enums.getEnum("MapState", "Loading")

-- protected / Network methods
local function playerLeaderstatsChanged(self, Player, teamIndex, goalsScored, numAssists, numTackles)
	self._PlayerTeamIndex[Player] = teamIndex
	self._PlayerGoals[Player] = goalsScored
	self._PlayerAssists[Player] = numAssists
	self._PlayerTackles[Player] = numTackles

	for callback, _ in self._PlayerLeaderstatsChangedCallbacks do
		callback(Player, teamIndex, goalsScored, numAssists, numTackles)
	end

	if teamIndex == nil then
		for callback, _ in self._PlayerLeftConnectedMapCallbacks do
			callback(Player)
		end
	end
end
local function playerConnectedMapChanged(self, Player, mapEnum, teamIndex)
	self._PlayerConnectedMapEnum[Player] = mapEnum
	self._PlayerTeamIndex[Player] = teamIndex

	if Player == self.Player then
		-- make any modals go away
		ClientModalState.setClientVisibleModal(self, nil)

		-- invoke joined callback for all players in the match when we join it (RETURNS)
		if mapEnum then
			for callback, _ in self._PlayerJoinedConnectedMapCallbacks do
				for OtherPlayer, _ in self._PlayerGoals do
					local otherTeamIndex = self._PlayerTeamIndex[OtherPlayer]
					callback(OtherPlayer, otherTeamIndex)
				end
			end

			return
		end

		-- invoke left callback for all players in the match when we leave (not including us, b/c that already happened)
		for callback, _ in self._PlayerLeftConnectedMapCallbacks do
			for OtherPlayer, _ in self._PlayerGoals do
				callback(OtherPlayer)
			end
		end

		return
	end

	-- invoke joined callbacks for other players that join our match after we did
	if mapEnum and mapEnum == self._PlayerConnectedMapEnum[self.Player] then
		for callback, _ in self._PlayerJoinedConnectedMapCallbacks do
			callback(Player, teamIndex)
		end
	end
end
local function playerConnectedMapStateChanged(self, mapStateEnum, stateEndTimestamp)
	self._ConnectedMapStateEnum = mapStateEnum
	self._ConnectedMapStateEndTimestamp = stateEndTimestamp

	-- mapState: 'nil' (map was destroyed) --> userInterfaceMode: 'Lobby'
	if mapStateEnum == nil then
		self._PlayerGoals = {}
		self._PlayerAssists = {}
		self._PlayerTackles = {}

		ClientUserInterfaceMode.setClientUserInterfaceMode(self, "Lobby")
		return
	end

	-- mapState: 'Loading' --> userInterfaceMode: 'LoadingMap'
	if mapStateEnum == LOADING_MAP_ENUM then
		ClientUserInterfaceMode.setClientUserInterfaceMode(self, "LoadingMap")
		return
	end

	-- userInterfaceMode = <mapState>
	local mapStateName = Enums.enumToName("MapState", mapStateEnum)
	ClientUserInterfaceMode.setClientUserInterfaceMode(self, mapStateName)
end

-- public / Client class methods
local function onPlayerLeftConnectedMap(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._PlayerLeftConnectedMapCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerLeftConnectedMapCallbacks[callback] = nil
		end,
	}
end
local function onPlayerJoinedConnectedMap(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for Player, goals in self._PlayerGoals do
		local teamIndex = self._PlayerTeamIndex[Player]
		callback(Player, teamIndex)
	end

	self._PlayerJoinedConnectedMapCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerJoinedConnectedMapCallbacks[callback] = nil
		end,
	}
end
local function getClientMapStateChangeTimestamp(self)
	return self._ConnectedMapStateEndTimestamp
end
local function onPlayerLeaderstatsChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for Player, numGoals in self._PlayerGoals do
		local teamIndex = self._PlayerTeamIndex[Player]
		local numAssists = self._PlayerAssists[Player]
		local numTackles = self._PlayerTackles[Player]

		callback(Player, teamIndex, numGoals, numAssists, numTackles)
	end

	self._PlayerLeaderstatsChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerLeaderstatsChangedCallbacks[callback] = nil
		end,
	}
end
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
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerLeaderstatsChanged", self.Player, function(...)
		playerLeaderstatsChanged(self, ...)
	end))
end

return {
	onPlayerLeaderstatsChangedConnect = onPlayerLeaderstatsChangedConnect,
	getClientMapStateChangeTimestamp = getClientMapStateChangeTimestamp,
	getClientConnectedMapName = getClientConnectedMapName,

	onPlayerJoinedConnectedMap = onPlayerJoinedConnectedMap,
	onPlayerLeftConnectedMap = onPlayerLeftConnectedMap,

	initialize = initializeClientMapState,
}
