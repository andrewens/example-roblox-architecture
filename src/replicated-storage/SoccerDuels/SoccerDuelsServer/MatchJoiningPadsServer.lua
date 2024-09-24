-- dependency
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local CHARACTER_TELEPORT_VERTICAL_OFFSET = Config.getConstant("CharacterTeleportVerticalOffset")
local LOBBY_DEVICE_COLLISION_GROUP = Config.getConstant("LobbyDeviceCollisionGroup")
local LOBBY_DEVICE_TRANSPARENCY = Config.getConstant("LobbyDeviceTransparency")
local CHARACTER_TOUCH_SENSOR_SIZE = Config.getConstant("CharacterTouchSensorSizeVector3")
local CHARACTER_TOUCH_SENSOR_PART_NAME = Config.getConstant("CharacterTouchSensorPartName")
local MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME = Config.getConstant("MatchJoiningPadIdentifierAttributeName")
local MATCH_JOINING_PAD_COUNTDOWN_DURATION_SECONDS = Config.getConstant("MatchJoiningPadCountdownDurationSeconds")
local MATCH_JOINING_PAD_MAP_VOTING_DURATION_SECONDS = Config.getConstant("MatchJoiningPadMapVotingDurationSeconds")
local MATCH_JOINING_PAD_STATE_CHANGE_POLL_RATE_SECONDS = Config.getConstant("MatchJoiningPadStateChangePollRateSeconds")

local TEAM1_COLOR = Config.getConstant("Team1Color")
local TEAM2_COLOR = Config.getConstant("Team2Color")

local WAITING_FOR_PLAYERS_STATE_ENUM = Enums.getEnum("MatchJoiningPadState", "WaitingForPlayers")
local COUNTDOWN_STATE_ENUM = Enums.getEnum("MatchJoiningPadState", "Countdown")
local MAP_VOTING_STATE_ENUM = Enums.getEnum("MatchJoiningPadState", "MapVoting")

-- var
local MaxPlayersPerTeam = {} -- int matchPadEnum --> int
local MatchPadTeamPlayers = {} -- int matchPadEnum --> int teamIndex --> Player --> true | nil
local PlayerConnectedMatchPad = {} -- Player --> [ int matchPadEnum, int teamIndex ]
local MatchPadState = {} -- int matchPadEnum --> int matchPadStateEnum
local extraSecondsForTesting = 0
local MatchPadStateChangeTimestamp = {} -- int matchPadEnum --> float timestampWhenStateChanges

-- private
local disconnectPlayerFromAllMatchPads
local function getTimestamp()
	return Utility.getUnixTimestamp() + extraSecondsForTesting
end
local function updateMatchPadState(matchPadEnum)
	local maxPlayers = MaxPlayersPerTeam[matchPadEnum]
	local numTeam1Players = Utility.tableCount(MatchPadTeamPlayers[matchPadEnum][1])
	local numTeam2Players = Utility.tableCount(MatchPadTeamPlayers[matchPadEnum][2])

	if numTeam1Players < maxPlayers or numTeam2Players < maxPlayers then
		MatchPadState[matchPadEnum] = WAITING_FOR_PLAYERS_STATE_ENUM
		MatchPadStateChangeTimestamp[matchPadEnum] = nil
		return
	end

	local timestampWhenStateChanges = MatchPadStateChangeTimestamp[matchPadEnum]
	local now = getTimestamp()

	if timestampWhenStateChanges == nil then
		-- previous state should have been 'WaitingForPlayers'
		MatchPadState[matchPadEnum] = COUNTDOWN_STATE_ENUM
		MatchPadStateChangeTimestamp[matchPadEnum] = now + MATCH_JOINING_PAD_COUNTDOWN_DURATION_SECONDS
		return
	end

	if now < timestampWhenStateChanges then
		return
	end

	if MatchPadState[matchPadEnum] == COUNTDOWN_STATE_ENUM then -- countdown --> map voting
		MatchPadState[matchPadEnum] = MAP_VOTING_STATE_ENUM
		MatchPadStateChangeTimestamp[matchPadEnum] = now + MATCH_JOINING_PAD_MAP_VOTING_DURATION_SECONDS
		return
	end

	MatchPadState[matchPadEnum] = WAITING_FOR_PLAYERS_STATE_ENUM
	MatchPadStateChangeTimestamp[matchPadEnum] = nil

	-- remove players from this match pad
	for Player, _ in MatchPadTeamPlayers[matchPadEnum][1] do
		disconnectPlayerFromAllMatchPads(Player)
	end
	for Player, _ in MatchPadTeamPlayers[matchPadEnum][2] do
		disconnectPlayerFromAllMatchPads(Player)
	end

	-- TODO actually put players into a match
end
local function clockTick()
	for matchPadEnum, _ in MatchPadStateChangeTimestamp do
		updateMatchPadState(matchPadEnum)
	end
end
local function removePlayerFromPreviousMatchPad(Player)
	if PlayerConnectedMatchPad[Player] == nil then
		return false
	end

	local matchPadEnum, teamIndex = table.unpack(PlayerConnectedMatchPad[Player])
	MatchPadTeamPlayers[matchPadEnum][teamIndex][Player] = nil

	PlayerConnectedMatchPad[Player] = nil
	updateMatchPadState(matchPadEnum)

	return true
end
local function addPlayerToMatchPad(Player, matchPadEnum, teamIndex)
	removePlayerFromPreviousMatchPad(Player)

	MatchPadTeamPlayers[matchPadEnum][teamIndex][Player] = true
	PlayerConnectedMatchPad[Player] = { matchPadEnum, teamIndex }
	updateMatchPadState(matchPadEnum)
end
function disconnectPlayerFromAllMatchPads(Player)
	if removePlayerFromPreviousMatchPad(Player) then -- (it returns true if the player was connected to a match pad)
		Network.fireAllClients("PlayerJoinedMatchPad", Player, nil, nil)
	end
end
local function connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)
	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	if matchPadName == nil then
		error(`{matchPadEnum} is not a match pad enum!`)
	end

	local TeamPlayers = MatchPadTeamPlayers[matchPadEnum][teamIndex]
	local maxPlayersPerTeam = MaxPlayersPerTeam[matchPadEnum]

	if Utility.tableCount(TeamPlayers) >= maxPlayersPerTeam then
		disconnectPlayerFromAllMatchPads(Player)
		return false
	end

	addPlayerToMatchPad(Player, matchPadEnum, teamIndex) -- (automatically removes player from previous match pad)

	Network.fireAllClients("PlayerJoinedMatchPad", Player, matchPadEnum, teamIndex)

	return true
end
local function getMatchPadPart(matchPadEnum, teamIndex)
	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	return Assets.getExpectedAsset(`{matchPadName} Pad{teamIndex}`)
end
local function initializeMatchJoinPad(Folder)
	local matchPadName = Folder.Name
	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		return
	end

	local maxPlayersPerTeam = tonumber(string.sub(matchPadName, 1, 1))

	local PadPart1 = Assets.getExpectedAsset(matchPadName .. " Pad1", matchPadName, Folder)
	local PadPart2 = Assets.getExpectedAsset(matchPadName .. " Pad2", matchPadName, Folder)

	local LightPart1 = Assets.getExpectedAsset(matchPadName .. " Pad1Light", matchPadName, Folder)
	local LightPart2 = Assets.getExpectedAsset(matchPadName .. " Pad2Light", matchPadName, Folder)

	PadPart1.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP
	PadPart2.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP

	PadPart1.Transparency = LOBBY_DEVICE_TRANSPARENCY
	PadPart2.Transparency = LOBBY_DEVICE_TRANSPARENCY

	PadPart1.Color = TEAM1_COLOR
	PadPart2.Color = TEAM2_COLOR

	PadPart1.CanCollide = false
	PadPart2.CanCollide = false

	PadPart1.CanQuery = false
	PadPart2.CanQuery = false

	PadPart1.CanTouch = true
	PadPart2.CanTouch = true

	PadPart1.Material = Enum.Material.Neon
	PadPart2.Material = Enum.Material.Neon

	PadPart1:SetAttribute(MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME, true)
	PadPart2:SetAttribute(MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME, true)

	LightPart1.Transparency = 1
	LightPart2.Transparency = 1

	LightPart1.Color = TEAM1_COLOR
	LightPart2.Color = TEAM2_COLOR

	MaxPlayersPerTeam[matchPadEnum] = maxPlayersPerTeam
	MatchPadState[matchPadEnum] = Enums.getEnum("MatchJoiningPadState", "WaitingForPlayers")
	MatchPadTeamPlayers[matchPadEnum] = {}
	MatchPadTeamPlayers[matchPadEnum][1] = {}
	MatchPadTeamPlayers[matchPadEnum][2] = {}
end

-- protected / Network methods
local function clientJoinMatchPad(Player, matchPadEnum, teamIndex)
	if Player.Character == nil or Player.Character.Parent == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if matchPadEnum == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)
end
local function clientDisconnectFromMatchPad(Player, matchPadEnum, teamIndex)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if PlayerConnectedMatchPad[Player] == nil then
		return
	end

	local playerMatchPadEnum, playerTeamIndex = table.unpack(PlayerConnectedMatchPad[Player])
	if not (playerMatchPadEnum == matchPadEnum and playerTeamIndex == teamIndex) then
		return
	end

	disconnectPlayerFromAllMatchPads(Player)
end

-- public
local function advanceMatchPadTimer(seconds)
	extraSecondsForTesting += seconds
	clockTick()
end
local function teleportPlayerToLobbySpawnLocation(Player)
	disconnectPlayerFromAllMatchPads(Player)

	local Char = Player.Character
	if Char == nil then
		return
	end

	local LobbySpawn = Assets.getExpectedAsset("LobbySpawnLocation")
	Char:MoveTo(LobbySpawn.Position + Vector3.new(0, CHARACTER_TELEPORT_VERTICAL_OFFSET, 0))
end
local function getMatchPadState(matchPadName)
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not a MatchJoiningPad!`)
	end

	local matchPadStateEnum = MatchPadState[matchPadEnum]

	return Enums.enumToName("MatchJoiningPadState", matchPadStateEnum)
end
local function getMatchPadTeamPlayers(matchPadName)
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not a MatchJoiningPad!`)
	end

	local TeamPlayersArray = {}
	for teamIndex, TeamPlayersDictionary in MatchPadTeamPlayers[matchPadEnum] do
		TeamPlayersArray[teamIndex] = Utility.dictionaryToArray(TeamPlayersDictionary)
	end

	return TeamPlayersArray
end
local function getPlayerConnectedMatchPadName(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if PlayerConnectedMatchPad[Player] == nil then
		return
	end

	local matchPadEnum = PlayerConnectedMatchPad[Player][1]

	return Enums.enumToName("MatchJoiningPad", matchPadEnum)
end
local function getPlayerConnectedMatchPadTeamIndex(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if PlayerConnectedMatchPad[Player] == nil then
		return 1
	end

	return PlayerConnectedMatchPad[Player][2]
end
local function playerCharacterLoaded(Player, Character)
	local TouchSensorPart = Instance.new("Part")
	TouchSensorPart.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP
	TouchSensorPart.Transparency = LOBBY_DEVICE_TRANSPARENCY
	TouchSensorPart.Size = CHARACTER_TOUCH_SENSOR_SIZE
	TouchSensorPart.Name = CHARACTER_TOUCH_SENSOR_PART_NAME
	TouchSensorPart.Color = Color3.new(1, 0, 1)
	TouchSensorPart.Material = Enum.Material.Neon
	TouchSensorPart.CanCollide = false
	TouchSensorPart.CanQuery = false
	TouchSensorPart.CanTouch = true

	Utility.weldPartToPart(TouchSensorPart, Character.HumanoidRootPart)

	TouchSensorPart.Parent = Character
end
local function disconnectPlayer(Player)
	disconnectPlayerFromAllMatchPads(Player)
end
local function teleportPlayerToMatchPad(Player, matchPadName, teamIndex)
	-- TODO return if player is disconnected from SoccerDuelsServer (?)

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
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

	local Char = Player.Character
	if Char == nil then
		return
	end

	local MatchPadPart = getMatchPadPart(matchPadEnum, teamIndex)
	Char:MoveTo(MatchPadPart.Position + Vector3.new(0, CHARACTER_TELEPORT_VERTICAL_OFFSET, 0))

	connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)
end
local function getMatchJoiningPads()
	local Pads = {}

	for matchPadEnum, maxPlayersPerTeam in MaxPlayersPerTeam do
		Pads[matchPadEnum] = {
			Name = Enums.enumToName("MatchJoiningPad", matchPadEnum),
			MaxPlayersPerTeam = maxPlayersPerTeam,
			Team1 = table.clone(MatchPadTeamPlayers[matchPadEnum][1]),
			Team2 = table.clone(MatchPadTeamPlayers[matchPadEnum][2]),
		}
	end

	return Pads
end
local function playerDataLoaded(Player)
	for OtherPlayer, MatchPadData in PlayerConnectedMatchPad do
		local matchPadEnum, teamIndex = table.unpack(MatchPadData)
		Network.fireClient("PlayerJoinedMatchPad", Player, OtherPlayer, matchPadEnum, teamIndex)
	end
end
local function initializeMatchJoiningPads()
	local MatchJoiningPadsFolder = Assets.getExpectedAsset("MatchJoiningPadsFolder")
	for _, Folder in MatchJoiningPadsFolder:GetChildren() do
		initializeMatchJoinPad(Folder)
	end

	Network.onServerInvokeConnect("PlayerJoinMatchPad", clientJoinMatchPad)
	Network.onServerInvokeConnect("PlayerDisconnectFromMatchPad", clientDisconnectFromMatchPad)

	-- workspace.TouchesUseCollisionGroups needs to be set to true for this optimization to work
	PhysicsService:RegisterCollisionGroup(LOBBY_DEVICE_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(LOBBY_DEVICE_COLLISION_GROUP, "Default", false)

	Utility.onCharacterLoadedConnect(playerCharacterLoaded)
	Utility.runServiceSteppedConnect(MATCH_JOINING_PAD_STATE_CHANGE_POLL_RATE_SECONDS, clockTick)
end

return {
	advanceMatchPadTimer = advanceMatchPadTimer,
	getMatchPadState = getMatchPadState,
	getMatchPadTeamPlayers = getMatchPadTeamPlayers,
	getMatchJoiningPads = getMatchJoiningPads,
	getPlayerConnectedMatchPadName = getPlayerConnectedMatchPadName,
	getPlayerConnectedMatchPadTeam = getPlayerConnectedMatchPadTeamIndex,

	teleportPlayerToLobbySpawnLocation = teleportPlayerToLobbySpawnLocation,
	teleportPlayerToMatchPad = teleportPlayerToMatchPad,

	playerCharacterLoaded = playerCharacterLoaded,
	disconnectPlayer = disconnectPlayer,
	playerDataLoaded = playerDataLoaded,
	initialize = initializeMatchJoiningPads,
}
