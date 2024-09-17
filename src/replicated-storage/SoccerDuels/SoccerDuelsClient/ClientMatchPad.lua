-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

local ClientUserInterfaceMode = require(SoccerDuelsClientModule.ClientUserInterfaceMode)

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

local function clientJoinMatchPadAsync(self, matchPadName, teamIndex)
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

	Network.invokeServer("PlayerJoinMatchPad", self.Player, matchPadEnum, teamIndex)
end
local function clientDisconnectFromMatchPadAsync(self)
	if self._PlayerSaveData[self.Player] == nil then
		error(`{self.Player} hasn't loaded their data yet!`)
	end

	Network.invokeServer("PlayerJoinMatchPad", self.Player, nil)
end

local function initializeClientMatchPad(self)
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerJoinedMatchPad", self.Player, function(...)
		clientConnectedMatchPadChanged(self, ...)
	end))
end

return {
	getClientConnectedMatchPadName = getClientConnectedMatchPadName,
	getClientConnectedMatchPadTeam = getClientConnectedMatchPadTeam,

	clientDisconnectFromMatchPadAsync = clientDisconnectFromMatchPadAsync,
	clientJoinMatchPadAsync = clientJoinMatchPadAsync,

	initialize = initializeClientMatchPad,
}
