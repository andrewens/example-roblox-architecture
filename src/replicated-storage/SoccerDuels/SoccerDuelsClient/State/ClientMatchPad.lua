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

-- private
local function getMatchPadPart(matchPadEnum, teamIndex)
	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	return Assets.getExpectedAsset(`{matchPadName} Pad{teamIndex}`)
end

-- protected / Network methods
local function clientConnectedMatchPadChanged(self, newMatchPadEnum, teamIndex)
	self._ConnectedMatchJoiningPadEnum = newMatchPadEnum
	self._ConnectedMatchJoiningPadTeamIndex = teamIndex

	ClientUserInterfaceMode.setClientUserInterfaceMode(self, if newMatchPadEnum then "MatchJoiningPad" else "Lobby")
end

-- public / Client class methods
local function getClientConnectedMatchPadName(self)
	return Enums.enumToName("MatchJoiningPad", self._ConnectedMatchJoiningPadEnum)
end
local function getClientConnectedMatchPadTeam(self)
	return self._ConnectedMatchJoiningPadTeamIndex or 1
end
local function clientTeleportToMatchPadAsync(self, matchPadName, teamIndex)
	if self._PlayerSaveData[self.Player] == nil then
		error(`{self.Player} hasn't loaded their data yet!`)
	end
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not the name of a match joining pad!`)
	end

	local Char = self.Player.Character
	if Char == nil then
		return
	end

	Network.invokeServer("PlayerJoinMatchPad", self.Player, matchPadEnum, teamIndex)

	local MatchPadPart = getMatchPadPart(matchPadEnum, teamIndex)
	if
		not Utility.playerCharacterIsInsideSpherePart(self.Player, MatchPadPart, MATCH_JOINING_PAD_RADIUS_PADDING_STUDS)
	then
		Char:MoveTo(MatchPadPart.Position + Vector3.new(0, 3, 0))
	end
end
local function clientDisconnectFromMatchPadAsync(self, matchPad)
	if self._PlayerSaveData[self.Player] == nil then
		error(`{self.Player} hasn't loaded their data yet!`)
	end
	if self._ConnectedMatchJoiningPadEnum == nil then
		return
	end

	Network.invokeServer("PlayerJoinMatchPad", self.Player, nil)
end
local function disconnectClientFromMatchPadIfCharacterSteppedOffAsync(self)
	local matchPadEnum = self._ConnectedMatchJoiningPadEnum
	local teamIndex = self._ConnectedMatchJoiningPadTeamIndex

	if matchPadEnum == nil then
		return
	end

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

	Network.invokeServer("PlayerJoinMatchPad", self.Player, matchPadEnum, teamIndex)
end
local function initializeClientMatchPad(self)
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerJoinedMatchPad", self.Player, function(...)
		clientConnectedMatchPadChanged(self, ...)
	end))

	self._Maid:GiveTask(Utility.runServiceSteppedConnect(PLAYER_STEPPED_OFF_MATCH_PAD_POLL_RATE_SECONDS, function(t, dt)
		task.spawn(disconnectClientFromMatchPadIfCharacterSteppedOffAsync, self)
	end))
end

return {
	disconnectClientFromMatchPadIfCharacterSteppedOffAsync = disconnectClientFromMatchPadIfCharacterSteppedOffAsync,

	getClientConnectedMatchPadName = getClientConnectedMatchPadName,
	getClientConnectedMatchPadTeam = getClientConnectedMatchPadTeam,

	clientTeleportToMatchPadAsync = clientTeleportToMatchPadAsync,
	touchedMatchJoiningPadPartAsync = touchedMatchJoiningPadPartAsync,

	initialize = initializeClientMatchPad,
}
