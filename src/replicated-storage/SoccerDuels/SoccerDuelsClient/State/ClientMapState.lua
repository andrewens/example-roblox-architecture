-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local ClientModalState = require(SoccerDuelsClientStateFolder.ClientModalState)
local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)
local PlayerCharactersInMap = require(SoccerDuelsClientStateFolder.PlayerCharactersInMap)

-- const
local LOADING_MAP_ENUM = Enums.getEnum("MapState", "Loading")
local MATCH_COUNTDOWN_STATE_ENUM = Enums.getEnum("MapState", "MatchCountdown")
local MATCH_GAMEPLAY_STATE_ENUM = Enums.getEnum("MapState", "MatchGameplay")
local MATCH_OVER_STATE_ENUM = Enums.getEnum("MapState", "MatchOver")

local MATCH_OVER_DURATION = Config.getConstant("MatchOverDurationSeconds")
local GOAL_CUTSCENE_DURATION = Config.getConstant("GoalCutsceneDurationSeconds")
local GOAL_CUTSCENE_FRAMES_PER_SECOND = Config.getConstant("GoalCutsceneFramesPerSecond")
local SECONDS_AFTER_GOAL_UNTIL_CUTSCENE_ENDS = Config.getConstant("SecondsAfterGoalUntilGoalCutsceneEnds")

local GOAL_CUTSCENE_SECONDS_PER_FRAME = 1 / GOAL_CUTSCENE_FRAMES_PER_SECOND
local TOTAL_FRAMES_PER_GOAL_CUTSCENE = GOAL_CUTSCENE_DURATION * GOAL_CUTSCENE_FRAMES_PER_SECOND

-- protected / Network methods
local function clientConnectedMapScoreChanged(self, team1Score, team2Score)
	if team1Score == nil then
		self._ClientConnectedMatchScore = nil

		for callback, _ in self._ClientConnectedMatchScoreChangedCallbacks do
			callback(0, 0)
		end

		return
	end

	self._ClientConnectedMatchScore = { team1Score, team2Score }

	for callback, _ in self._ClientConnectedMatchScoreChangedCallbacks do
		callback(team1Score, team2Score)
	end
end
local function playerLeaderstatsChanged(self, Player, teamIndex, goalsScored, numAssists, numTackles)
	if typeof(goalsScored) == "number" and goalsScored > 0 and goalsScored ~= self._PlayerGoals[Player] then
		self._PlayerThatScoredLastGoal = Player
	end

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
local function playerConnectedMapChanged(self, Player, mapEnum, teamIndex, MapFolder)
	self._PlayerConnectedMapEnum[Player] = mapEnum
	self._PlayerTeamIndex[Player] = teamIndex

	-- LocalPlayer
	if Player == self.Player then
		self._ConnectedMapFolder = MapFolder

		-- reset data
		self._PlayerThatScoredLastGoal = nil
		self._PlayerCFrames = nil
		--self._PlayerCFrameFrameIndex = nil

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

	-- mapState: 'MatchCountdown' --> reset _PlayerThatScoredLastGoal, _PlayerCFrames
	if mapStateEnum == MATCH_COUNTDOWN_STATE_ENUM then
		self._PlayerThatScoredLastGoal = nil
		self._PlayerCFrames = {}
		--self._PlayerCFrameFrameIndex = 1
	end

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
local getClientMapStateChangeTimestamp
local function disconnectClientFromAllMapInstances(self)
	Network.fireServer("PlayerDisconnectFromAllMapInstances", self.Player)
end

local function iterateEndOfMatchPlayerCFrames(self)
	local i = 0
	return function()
		i += 1

		if self._PlayerCFrames[i] == nil then
			return
		end

		return i, self._PlayerCFrames[i], self._PlayerHumanoidStates[i]
	end
end
local function mapTimerTick(self)
	local mapStateEnum = self._ConnectedMapStateEnum
	if not (mapStateEnum == MATCH_GAMEPLAY_STATE_ENUM or mapStateEnum == MATCH_OVER_STATE_ENUM) then
		return
	end

	local now = Time.getUnixTimestampMilliseconds()
	local timestamp = getClientMapStateChangeTimestamp(self)
	if
		mapStateEnum == MATCH_OVER_STATE_ENUM
		and now > (timestamp + (-MATCH_OVER_DURATION + SECONDS_AFTER_GOAL_UNTIL_CUTSCENE_ENDS) * 1E3)
	then
		return
	end

	local PlayerCFramesAtThisFrame = {}
	local PlayerHumanoidStatesAtThisFrame = {}

	for Player, _ in self._PlayerGoals do
		PlayerCFramesAtThisFrame[Player] = Utility.getPlayerCharacterCFrame(Player) -- this accounts for players leaving or having no character
		PlayerHumanoidStatesAtThisFrame[Player] = Utility.getPlayerCharacterHumanoidState(Player)
	end

	if #self._PlayerCFrames >= TOTAL_FRAMES_PER_GOAL_CUTSCENE then
		table.remove(self._PlayerCFrames, 1) -- TODO could implement a circular array buffer to prevent down-shifting every item in the lsit
		table.remove(self._PlayerHumanoidStates, 1)
	end

	table.insert(self._PlayerCFrames, PlayerCFramesAtThisFrame)
	table.insert(self._PlayerHumanoidStates, PlayerHumanoidStatesAtThisFrame)
end

local function getClientConnectedMapPlayerLeaderstat(self, Player, leaderstat)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if leaderstat == "Goals" then
		return self._PlayerGoals[Player]
	end

	if leaderstat == "Assists" then
		return self._PlayerAssists[Player]
	end

	if leaderstat == "Tackles" then
		return self._PlayerTackles[Player]
	end

	error(`There's no leaderstat named "{leaderstat}"`)
end
local function getClientedConnectedMapTeamMostValuablePlayer(self, teamIndex)
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	--[[
			is new mvp?   goals  assists  tackles
			Y				>		>		>
			Y				>		>		==
			Y				>		>		<
			Y				>		==		>
			Y				>		==		==
			Y				>		==		<
			Y				>		<		>
			Y				>		<		==
			Y				>		<		<
			Y				==		>		>
			Y				==		>		==
			Y				==		>		<
			Y				==		==		>
		delete MVP (tie)	==		==		==
			N				==		==		<
			N				==		<		>
			N				==		<		==
			N				==		<		<
			N				<		>		<
			N				<		>		==
			N				<		>		>
			N				<		==		>
			N				<		==		==
			N				<		==		<
			N				<		<		>
			N				<		<		==
			N				<		<		<
	]]

	local mvpGoals = 0
	local mvpAssists = 0
	local mvpTackles = 0
	local MVPPlayer

	for Player, numGoals in self._PlayerGoals do
		if self._PlayerTeamIndex[Player] ~= teamIndex then
			continue
		end

		local numAssists = self._PlayerAssists[Player]
		local numTackles = self._PlayerTackles[Player]

		if numGoals == mvpGoals and numAssists == mvpAssists and numTackles == mvpTackles then
			MVPPlayer = nil
			continue
		end
		if
			numGoals < mvpGoals
			or (numGoals == mvpGoals and numAssists < mvpAssists)
			or (numGoals == mvpGoals and numAssists == mvpAssists and numTackles < mvpTackles)
		then
			continue
		end

		MVPPlayer = Player
		mvpGoals = numGoals
		mvpAssists = numAssists
		mvpTackles = numTackles
	end

	return MVPPlayer
end
local function getClientConnectedMapTeamPlayers(self, teamIndex)
	if teamIndex == nil then
		teamIndex = self._PlayerTeamIndex[self.Player]
	end

	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	local PlayersOnThisTeam = {}

	for Player, _ in self._PlayerGoals do
		local playerTeamIndex = self._PlayerTeamIndex[Player]
		if playerTeamIndex == teamIndex then
			table.insert(PlayersOnThisTeam, Player)
		end
	end

	return PlayersOnThisTeam
end

local function getPlayerWhoScoredLastGoalInClientConnectedMap(self)
	return self._PlayerThatScoredLastGoal
end
local function getPlayerWhoAssistedLastGoalInClientConnectedMap(self)
	return self._PlayerThatScoredLastGoal -- TODO properly test & implement this
end

local function getClientConnectedMapFolder(self)
	return self._ConnectedMapFolder
end
local function getClientConnectedMapTeamScore(self, teamIndex)
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	if self._ClientConnectedMatchScore == nil then
		return 0
	end

	return self._ClientConnectedMatchScore[teamIndex]
end
local function getClientConnectedMapWinningTeamIndex(self)
	if self._ClientConnectedMatchScore == nil then
		return nil
	end

	local team1Score, team2Score = table.unpack(self._ClientConnectedMatchScore)
	if team1Score == team2Score then
		return nil
	end

	return if team1Score > team2Score then 1 else 2
end
local function onClientMapScoreChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	if self._ClientConnectedMatchScore then
		callback(table.unpack(self._ClientConnectedMatchScore))
	end

	self._ClientConnectedMatchScoreChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._ClientConnectedMatchScoreChangedCallbacks[callback] = nil
		end,
	}
end
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
function getClientMapStateChangeTimestamp(self)
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
	self.Maid:GiveTask(Network.onClientEventConnect("MapStateChanged", self.Player, function(...)
		playerConnectedMapStateChanged(self, ...)
	end))
	self.Maid:GiveTask(Network.onClientEventConnect("PlayerConnectedMapChanged", self.Player, function(...)
		playerConnectedMapChanged(self, ...)
	end))
	self.Maid:GiveTask(Network.onClientEventConnect("PlayerLeaderstatsChanged", self.Player, function(...)
		playerLeaderstatsChanged(self, ...)
	end))
	self.Maid:GiveTask(Network.onClientEventConnect("MatchScoreChanged", self.Player, function(...)
		clientConnectedMapScoreChanged(self, ...)
	end))
	self.Maid:GiveTask(Utility.runServiceSteppedConnect(GOAL_CUTSCENE_SECONDS_PER_FRAME, function(...)
		mapTimerTick(self, ...)
	end))
end

return {
	iterateEndOfMatchPlayerCFrames = iterateEndOfMatchPlayerCFrames,
	mapTimerTick = mapTimerTick,

	getPlayerWhoAssistedLastGoalInClientConnectedMap = getPlayerWhoAssistedLastGoalInClientConnectedMap,
	getPlayerWhoScoredLastGoalInClientConnectedMap = getPlayerWhoScoredLastGoalInClientConnectedMap,

	onPlayerLeaderstatsChangedConnect = onPlayerLeaderstatsChangedConnect,
	onClientMapScoreChangedConnect = onClientMapScoreChangedConnect,

	getClientedConnectedMapTeamMostValuablePlayer = getClientedConnectedMapTeamMostValuablePlayer,
	getClientConnectedMapPlayerLeaderstat = getClientConnectedMapPlayerLeaderstat,
	getClientConnectedMapWinningTeamIndex = getClientConnectedMapWinningTeamIndex,
	getClientConnectedMapTeamPlayers = getClientConnectedMapTeamPlayers,
	getClientMapStateChangeTimestamp = getClientMapStateChangeTimestamp,
	getClientConnectedMapTeamScore = getClientConnectedMapTeamScore,
	getClientConnectedMapFolder = getClientConnectedMapFolder,
	getClientConnectedMapName = getClientConnectedMapName,

	onPlayerJoinedConnectedMap = onPlayerJoinedConnectedMap,
	onPlayerLeftConnectedMap = onPlayerLeftConnectedMap,

	disconnectClientFromAllMapInstances = disconnectClientFromAllMapInstances,

	initialize = initializeClientMapState,
}
