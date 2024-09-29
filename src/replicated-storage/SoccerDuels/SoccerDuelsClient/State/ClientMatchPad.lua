-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)

-- const
local MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME = Config.getConstant("MatchJoiningPadIdentifierAttributeName")
local MATCH_JOINING_PAD_RADIUS_PADDING_STUDS = Config.getConstant("MatchJoiningPadRadiusPaddingStuds")
local PLAYER_STEPPED_OFF_MATCH_PAD_POLL_RATE_SECONDS =
	Config.getConstant("SecondsBetweenCheckingIfPlayerSteppedOffMatchJoiningPad")

local MAP_VOTING_STATE_ENUM = Enums.getEnum("MatchJoiningPadState", "MapVoting")
local WAITING_FOR_PLAYERS_STATE_ENUM = Enums.getEnum("MatchJoiningPadState", "WaitingForPlayers")

local TEAM1_COLOR = Config.getConstant("Team1Color")
local TEAM2_COLOR = Config.getConstant("Team2Color")

-- private
local function getMatchPadPart(matchPadEnum, teamIndex)
	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	return Assets.getExpectedAsset(`{matchPadName} Pad{teamIndex}`)
end

-- protected / Network methods
local function playerVotedForMap(self, matchPadEnum, Player, mapEnum)
	if matchPadEnum ~= self._PlayerConnectedMatchPadEnum[self.Player] then
		return
	end

	if self._PlayerMapVotes[Player] == mapEnum then
		return
	end

	self._PlayerMapVotes[Player] = mapEnum

	local mapName = Enums.enumToName("Map", mapEnum)
	for callback, _ in self._PlayerVotedOnMapCallbacks do
		callback(Player, mapName)
	end
end
local function matchPadStateChanged(self, matchPadEnum, matchPadStateEnum, stateChangeTimestamp)
	self._MatchJoiningPadStateEnum[matchPadEnum] = matchPadStateEnum
	self._MatchJoiningPadStateChangeTimestamp[matchPadEnum] = stateChangeTimestamp

	-- Client self.Player's match pad only below this
	if self._PlayerConnectedMatchPadEnum[self.Player] ~= matchPadEnum then
		return
	end

	self._PlayerMapVotes = {}

	ClientUserInterfaceMode.setClientUserInterfaceMode(
		self,
		if matchPadStateEnum == MAP_VOTING_STATE_ENUM then "MapVoting" else "MatchJoiningPad"
	)

	local matchPadStateName = Enums.enumToName("MatchJoiningPadState", matchPadStateEnum)
	for callback, _ in self._PlayerConnectedMatchPadStateChangedCallbacks do
		callback(matchPadStateName, stateChangeTimestamp)
	end
end
local function clientConnectedMatchPadChanged(self, Player, newMatchPadEnum, teamIndex)
	if Utility.shouldIgnoreMockPlayerFromServerTests(Player) then
		return
	end

	self._PlayerConnectedMatchPadEnum[Player] = newMatchPadEnum
	self._PlayerConnectedMatchPadTeam[Player] = teamIndex

	-- update user interface mode
	if Player == self.Player then
		ClientUserInterfaceMode.setClientUserInterfaceMode(self, if newMatchPadEnum then "MatchJoiningPad" else "Lobby")
	end

	-- player match pad changed callback
	local matchPadName
	if newMatchPadEnum then
		matchPadName = Enums.enumToName("MatchJoiningPad", newMatchPadEnum)
	end

	teamIndex = teamIndex or 1

	for callback, _ in self._PlayerMatchPadChangedCallbacks do
		callback(Player, matchPadName, teamIndex)
	end

	-- this player's connected match pad state changed callback
	if Player == self.Player then
		local matchPadStateEnum = self._MatchJoiningPadStateEnum[newMatchPadEnum]
		local stateChangeTimestamp = self._MatchJoiningPadStateChangeTimestamp[newMatchPadEnum]
		local matchPadStateName = Enums.enumToName("MatchJoiningPadState", matchPadStateEnum)

		for callback, _ in self._PlayerConnectedMatchPadStateChangedCallbacks do
			callback(matchPadStateName, stateChangeTimestamp)
		end
	end
end

-- public / Client class methods
local function anyMatchPadIsFull(self, matchPadName) -- TODO untested
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`"{matchPadName}" is not the name of a MatchJoiningPad!`)
	end

	local maxPlayersPerTeam = tonumber(string.sub(matchPadName, 1, 1))
	local playersOnMatchPad = 0

	for Player, otherMatchPadEnum in self._PlayerConnectedMatchPadEnum do
		if otherMatchPadEnum ~= matchPadEnum then
			continue
		end

		playersOnMatchPad += 1
		if playersOnMatchPad >= 2 * maxPlayersPerTeam then
			return true
		end
	end

	return false
end
local function anyMatchPadIsEmpty(self, matchPadName) -- TODO untested
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`"{matchPadName}" is not the name of a MatchJoiningPad!`)
	end

	for Player, otherMatchPadEnum in self._PlayerConnectedMatchPadEnum do
		if otherMatchPadEnum == matchPadEnum then
			return false
		end
	end

	return true
end
local function onClientConnectedMatchPadVoteChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for Player, mapEnum in self._PlayerMapVotes do
		local mapName = Enums.enumToName("Map", mapEnum)
		callback(Player, mapName)
	end

	self._PlayerVotedOnMapCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerVotedOnMapCallbacks[callback] = nil
		end,
	}
end
local function getAnyMatchPadState(self, matchPadName)
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`"{matchPadName}" is not the name of a MatchJoiningPad!`)
	end

	local matchPadStateEnum = self._MatchJoiningPadStateEnum[matchPadEnum]
	return Enums.enumToName("MatchJoiningPadState", matchPadStateEnum)
end
local function onPlayerConnectedMatchPadStateChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local matchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	if matchPadEnum then
		local matchPadStateEnum = self._MatchJoiningPadStateEnum[matchPadEnum]
		local stateChangeTimestamp = self._MatchJoiningPadStateChangeTimestamp[matchPadEnum]
		local matchPadStateName = Enums.enumToName("MatchJoiningPadState", matchPadStateEnum)

		callback(matchPadStateName, stateChangeTimestamp)
	end

	self._PlayerConnectedMatchPadStateChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerConnectedMatchPadStateChangedCallbacks[callback] = nil
		end,
	}
end
local function onLobbyCharacterTouchedMatchPadConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._CharacterTouchedMatchPadCallbacks[callback] = true

	return {
		Disconnect = function()
			self._CharacterTouchedMatchPadCallbacks[callback] = nil
		end,
	}
end
local function onAnyPlayerMatchPadChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	for Player, matchPadEnum in self._PlayerConnectedMatchPadEnum do
		local teamIndex = self._PlayerConnectedMatchPadTeam[Player]
		local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)

		callback(Player, matchPadName, teamIndex)
	end

	self._PlayerMatchPadChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._PlayerMatchPadChangedCallbacks[callback] = nil
		end,
	}
end
local function getClientConnectedMatchPadState(self) -- TODO this might be untested
	local matchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	if matchPadEnum == nil then
		return
	end

	return Enums.enumToName("MatchJoiningPadState", self._MatchJoiningPadStateEnum[matchPadEnum])
end
local function getClientConnectedMatchPadStateChangeTimestamp(self) -- TODO this is untested
	local matchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	if matchPadEnum == nil then
		return
	end

	return self._MatchJoiningPadStateChangeTimestamp[matchPadEnum]
end
local function getClientConnectedMatchPadName(self)
	local matchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	return Enums.enumToName("MatchJoiningPad", matchPadEnum)
end
local function getClientConnectedMatchPadTeam(self, Player)
	return self._PlayerConnectedMatchPadTeam[Player or self.Player] or 1
end
local function clientVoteForMap(self, mapName)
	if self._PlayerSaveData[self.Player] == nil then
		error(`Client data isn't loaded!`)
	end

	if getClientConnectedMatchPadState(self) ~= "MapVoting" then
		return
	end

	if mapName == nil then
		Network.fireServer("PlayerVoteForMap", self.Player, nil)
		return
	end

	if not (typeof(mapName) == "string") then
		error(`{mapName} is not a string!`)
	end

	local mapEnum = Enums.getEnum("Map", mapName)
	if mapEnum == nil then
		error(`"{mapName}" is not the name of a map!`)
	end

	Network.fireServer("PlayerVoteForMap", self.Player, mapEnum)
end
local function clientTeleportToMatchPadAsync(self, matchPadName, teamIndex)
	if self._PlayerSaveData[self.Player] == nil then
		error(`{self.Player} hasn't loaded their data yet!`)
	end
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end
	if not (teamIndex == nil or teamIndex == 1 or teamIndex == 2) then
		-- if `teamIndex` is nil, then server will automatically assign player a teamIndex
		error(`{teamIndex} is not 1 or 2!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not the name of a match joining pad!`)
	end

	Network.invokeServer("TeleportPlayerToMatchPad", self.Player, matchPadEnum, teamIndex)
end
local function disconnectClientFromMatchPadIfCharacterSteppedOffAsync(self)
	local matchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	if matchPadEnum == nil then
		return
	end

	local teamIndex = self._PlayerConnectedMatchPadTeam[self.Player]
	local MatchPadPart = getMatchPadPart(matchPadEnum, teamIndex)
	if
		not Utility.playerCharacterIsInsideSpherePart(self.Player, MatchPadPart, MATCH_JOINING_PAD_RADIUS_PADDING_STUDS)
	then
		-- only disconnect if client is still connected to this specific match pad
		Network.invokeServer("PlayerDisconnectFromMatchPad", self.Player, matchPadEnum, teamIndex)
	end
end
local function touchedMatchJoiningPadPartAsync(self, MatchPadPart)
	if not MatchPadPart:GetAttribute(MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME) then
		return
	end

	local MatchJoiningPadFolder = MatchPadPart.Parent
	local matchPadName = MatchJoiningPadFolder.Name

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not the name of a Match Joining Pad!`)
	end

	local teamIndex = tonumber(string.match(MatchPadPart.Name, "%d+")) -- extract the digit out of the pad name
	if teamIndex == nil then
		error(`{MatchPadPart.Name} has no team index!`)
	end

	local currentMatchPadEnum = self._PlayerConnectedMatchPadEnum[self.Player]
	local currentTeamIndex = self._PlayerConnectedMatchPadTeam[self.Player]

	if matchPadEnum == currentMatchPadEnum and teamIndex == currentTeamIndex then
		return
	end

	for callback, _ in self._CharacterTouchedMatchPadCallbacks do
		callback(matchPadName, teamIndex)
	end

	Network.invokeServer("PlayerJoinMatchPad", self.Player, matchPadEnum, teamIndex)
end
local function initializeClientMatchPad(self)
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerJoinedMatchPad", self.Player, function(...)
		clientConnectedMatchPadChanged(self, ...)
	end))

	self._Maid:GiveTask(Network.onClientEventConnect("MatchPadStateChanged", self.Player, function(...)
		matchPadStateChanged(self, ...)
	end))

	self._Maid:GiveTask(Network.onClientEventConnect("PlayerVoteForMap", self.Player, function(...)
		playerVotedForMap(self, ...)
	end))

	self._Maid:GiveTask(Utility.runServiceSteppedConnect(PLAYER_STEPPED_OFF_MATCH_PAD_POLL_RATE_SECONDS, function(t, dt)
		task.spawn(disconnectClientFromMatchPadIfCharacterSteppedOffAsync, self)
	end))
end

return {
	onClientConnectedMatchPadVoteChangedConnect = onClientConnectedMatchPadVoteChangedConnect,
	getAnyPlayerTeamIndex = getClientConnectedMatchPadTeam,
	clientVoteForMap = clientVoteForMap,

	onPlayerConnectedMatchPadStateChangedConnect = onPlayerConnectedMatchPadStateChangedConnect,
	onLobbyCharacterTouchedMatchPadConnect = onLobbyCharacterTouchedMatchPadConnect,
	onAnyPlayerMatchPadChangedConnect = onAnyPlayerMatchPadChangedConnect,

	getClientConnectedMatchPadStateChangeTimestamp = getClientConnectedMatchPadStateChangeTimestamp,
	getClientConnectedMatchPadName = getClientConnectedMatchPadName,
	getClientConnectedMatchPadTeam = getClientConnectedMatchPadTeam,

	disconnectClientFromMatchPadIfCharacterSteppedOffAsync = disconnectClientFromMatchPadIfCharacterSteppedOffAsync,
	touchedMatchJoiningPadPartAsync = touchedMatchJoiningPadPartAsync,
	clientTeleportToMatchPadAsync = clientTeleportToMatchPadAsync,

	getAnyMatchPadState = getAnyMatchPadState,
	anyMatchPadIsEmpty = anyMatchPadIsEmpty,
	anyMatchPadIsFull = anyMatchPadIsFull,
	initialize = initializeClientMatchPad,
}
