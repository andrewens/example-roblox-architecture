-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

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
end
local function playerConnectedMapChanged(self, Player, mapEnum, teamIndex)
	self._PlayerConnectedMapEnum[Player] = mapEnum
	self._PlayerTeamIndex[Player] = teamIndex
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

	initialize = initializeClientMapState,
}
