-- dependency
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)
local SoccerDuelsServer -- required in initialize()

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

local MATCH_JOINING_PAD_COUNTDOWN_DURATION_MILLISECONDS = MATCH_JOINING_PAD_COUNTDOWN_DURATION_SECONDS * 1E3
local MATCH_JOINING_PAD_MAP_VOTING_DURATION_MILLISECONDS = MATCH_JOINING_PAD_MAP_VOTING_DURATION_SECONDS * 1E3

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
local MatchPadStateChangeTimestamp = {} -- int matchPadEnum --> float timestampWhenStateChanges
local MatchPadMapVotes = {} -- int matchPadEnum --> Player --> mapEnum
local MatchPadLastPlayerWhoVoted = {} -- int matchPadEnum --> Player

-- private
local disconnectPlayerFromAllMatchPads
local function setMatchPadState(matchPadEnum, matchPadStateEnum, stateChangeTimestamp)
	MatchPadState[matchPadEnum] = matchPadStateEnum
	MatchPadStateChangeTimestamp[matchPadEnum] = stateChangeTimestamp

	MatchPadMapVotes[matchPadEnum] = {} -- votes need to get wiped when we leave the 'MapVoting' state
	MatchPadLastPlayerWhoVoted[matchPadEnum] = nil

	Network.fireAllClients("MatchPadStateChanged", matchPadEnum, matchPadStateEnum, stateChangeTimestamp)
end
local function updateMatchPadState(matchPadEnum)
	local maxPlayers = MaxPlayersPerTeam[matchPadEnum]
	local numTeam1Players = Utility.tableCount(MatchPadTeamPlayers[matchPadEnum][1])
	local numTeam2Players = Utility.tableCount(MatchPadTeamPlayers[matchPadEnum][2])

	if numTeam1Players < maxPlayers or numTeam2Players < maxPlayers then
		setMatchPadState(matchPadEnum, WAITING_FOR_PLAYERS_STATE_ENUM, nil)
		return
	end

	local timestampWhenStateChanges = MatchPadStateChangeTimestamp[matchPadEnum]
	local now = Time.getUnixTimestampMilliseconds()

	if timestampWhenStateChanges == nil then
		-- previous state should have been 'WaitingForPlayers'
		setMatchPadState(matchPadEnum, COUNTDOWN_STATE_ENUM, now + MATCH_JOINING_PAD_COUNTDOWN_DURATION_MILLISECONDS)
		return
	end

	if now < timestampWhenStateChanges then
		return
	end

	if MatchPadState[matchPadEnum] == COUNTDOWN_STATE_ENUM then -- countdown --> map voting
		setMatchPadState(matchPadEnum, MAP_VOTING_STATE_ENUM, now + MATCH_JOINING_PAD_MAP_VOTING_DURATION_MILLISECONDS)
		return
	end

	-- remove players from this match pad
	for Player, _ in MatchPadTeamPlayers[matchPadEnum][1] do
		disconnectPlayerFromAllMatchPads(Player)
	end
	for Player, _ in MatchPadTeamPlayers[matchPadEnum][2] do
		disconnectPlayerFromAllMatchPads(Player)
	end

	setMatchPadState(matchPadEnum, WAITING_FOR_PLAYERS_STATE_ENUM, nil)

	-- TODO actually put players into a match
end
local function removePlayerFromPreviousMatchPad(Player)
	if PlayerConnectedMatchPad[Player] == nil then
		return
	end

	local matchPadEnum, teamIndex = table.unpack(PlayerConnectedMatchPad[Player])
	MatchPadTeamPlayers[matchPadEnum][teamIndex][Player] = nil

	PlayerConnectedMatchPad[Player] = nil
	updateMatchPadState(matchPadEnum)

	return
end
local function addPlayerToMatchPad(Player, matchPadEnum, teamIndex)
	removePlayerFromPreviousMatchPad(Player)

	MatchPadTeamPlayers[matchPadEnum][teamIndex][Player] = true
	PlayerConnectedMatchPad[Player] = { matchPadEnum, teamIndex }
	updateMatchPadState(matchPadEnum)
end
function disconnectPlayerFromAllMatchPads(Player)
	if PlayerConnectedMatchPad[Player] == nil then
		return
	end

	Network.fireAllClients("PlayerJoinedMatchPad", Player, nil, nil)
	removePlayerFromPreviousMatchPad(Player)
end
local function connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)
	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	if matchPadName == nil then
		error(`{matchPadEnum} is not a match pad enum!`)
	end

	local Team1Players = MatchPadTeamPlayers[matchPadEnum][1]
	local Team2Players = MatchPadTeamPlayers[matchPadEnum][2]

	local team1PlayerCount = Utility.tableCount(Team1Players)
	local team2PlayerCount = Utility.tableCount(Team2Players)

	if teamIndex == nil then
		teamIndex = if team1PlayerCount <= team2PlayerCount then 1 else 2
	end

	local maxPlayersPerTeam = MaxPlayersPerTeam[matchPadEnum]
	local teamPlayerCount = if teamIndex == 1 then team1PlayerCount else team2PlayerCount

	if teamPlayerCount >= maxPlayersPerTeam then
		disconnectPlayerFromAllMatchPads(Player)
		return false
	end

	addPlayerToMatchPad(Player, matchPadEnum, teamIndex) -- (automatically removes player from previous match pad)

	Network.fireAllClients("PlayerJoinedMatchPad", Player, matchPadEnum, teamIndex)

	return true, teamIndex
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
	MatchPadMapVotes[matchPadEnum] = {}
end

-- protected / Network methods
local function clientVoteOnMap(Player, mapEnum)
	if PlayerConnectedMatchPad[Player] == nil then
		return
	end

	local matchPadEnum = table.unpack(PlayerConnectedMatchPad[Player])
	if MatchPadState[matchPadEnum] ~= MAP_VOTING_STATE_ENUM then
		return
	end

	if not (mapEnum == nil or Enums.enumToName("Map", mapEnum)) then
		error(`{mapEnum} is not a Map Enum!`)
	end

	MatchPadMapVotes[matchPadEnum][Player] = mapEnum
	MatchPadLastPlayerWhoVoted[matchPadEnum] = Player

	Network.fireAllClients("PlayerVoteForMap", matchPadEnum, Player, mapEnum)
end
local function clientTeleportToMatchPad(Player, matchPadEnum, teamIndex)
	local Char = Player.Character
	if Char == nil or Char.Parent == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if matchPadEnum == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if Enums.enumToName("MatchJoiningPad", matchPadEnum) == nil then
		error(`{matchPadEnum} is not a MatchJoiningPad Enum!`)
	end
	if not (teamIndex == nil or teamIndex == 1 or teamIndex == 2) then
		-- if `teamIndex` is nil, then connectPlayerToMatchPad() will automatically assign player a teamIndex
		error(`{teamIndex} is not a valid TeamIndex!`)
	end

	local success
	success, teamIndex = connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)

	if not success then
		return false
	end

	local MatchPadPart = getMatchPadPart(matchPadEnum, teamIndex)
	Char:MoveTo(MatchPadPart.Position + Vector3.new(0, 3, 0))

	return true, teamIndex
end
local function clientJoinMatchPad(Player, matchPadEnum, teamIndex)
	if Player.Character == nil or Player.Character.Parent == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if matchPadEnum == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if Enums.enumToName("MatchJoiningPad", matchPadEnum) == nil then
		error(`{matchPadEnum} is not a MatchJoiningPad Enum!`)
	end
	if not (teamIndex == nil or teamIndex == 1 or teamIndex == 2) then
		-- if `teamIndex` is nil, then connectPlayerToMatchPad() will automatically assign player a teamIndex
		error(`{teamIndex} is not a valid TeamIndex!`)
	end

	return connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)
end
local function clientDisconnectFromMatchPad(Player, matchPadEnum, teamIndex)
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
local function getMatchPadWinningMapVote(matchPadName)
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`"{matchPadName}" is not the name of a match joining pad!`)
	end

	-- tally votes
	local MapEnumVotes = {}
	local mostVotes = 0
	local winningMapEnum
	for Player, mapEnum in MatchPadMapVotes[matchPadEnum] do
		if MapEnumVotes[mapEnum] == nil then
			MapEnumVotes[mapEnum] = 0
		end
		MapEnumVotes[mapEnum] += 1

		-- last player who voted gets to break ties
		if MatchPadLastPlayerWhoVoted[matchPadEnum] == Player then
			MapEnumVotes[mapEnum] += 0.1
		end

		if MapEnumVotes[mapEnum] > mostVotes then
			mostVotes = MapEnumVotes[mapEnum]
			winningMapEnum = mapEnum
		end
	end

	if winningMapEnum then
		local winningMapName = Enums.enumToName("Map", winningMapEnum)
		return winningMapName
	end

	return nil
end
local function getMatchPadMapVotes(matchPadName)
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`"{matchPadName}" is not the name of a match joining pad!`)
	end

	-- tally votes
	local MapEnumVotes = {}
	for Player, mapEnum in MatchPadMapVotes[matchPadEnum] do
		if MapEnumVotes[mapEnum] == nil then
			MapEnumVotes[mapEnum] = 0
		end
		MapEnumVotes[mapEnum] += 1
	end

	-- format by map name
	local MapNameVotes = {}
	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		MapNameVotes[mapName] = MapEnumVotes[mapEnum] or 0
	end

	return MapNameVotes
end
local function matchPadTimerTick()
	for matchPadEnum, _ in MatchPadStateChangeTimestamp do
		updateMatchPadState(matchPadEnum)
	end
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
local function teleportPlayerToLobbySpawnLocation(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		--error(`{Player.Name}'s data is not loaded!`)
		return
	end

	disconnectPlayerFromAllMatchPads(Player)

	local Char = Player.Character
	if Char == nil then
		return
	end

	local LobbySpawn = Assets.getExpectedAsset("LobbySpawnLocation")
	Char:MoveTo(LobbySpawn.Position + Vector3.new(0, CHARACTER_TELEPORT_VERTICAL_OFFSET, 0))
end
local function teleportPlayerToMatchPad(Player, matchPadName, teamIndex)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		--error(`{Player.Name}'s data is not loaded!`)
		return
	end
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end
	if not (teamIndex == nil or teamIndex == 1 or teamIndex == 2) then
		-- if `teamIndex` is nil, then connectPlayerToMatchPad() will automatically assign player a teamIndex
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

	local success
	success, teamIndex = connectPlayerToMatchPad(Player, matchPadEnum, teamIndex)

	if not success then
		return false
	end

	local MatchPadPart = getMatchPadPart(matchPadEnum, teamIndex)
	Char:MoveTo(MatchPadPart.Position + Vector3.new(0, CHARACTER_TELEPORT_VERTICAL_OFFSET, 0))

	return true
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
local function onPlayerDataLoaded(Player)
	for OtherPlayer, MatchPadData in PlayerConnectedMatchPad do
		local matchPadEnum, teamIndex = table.unpack(MatchPadData)
		Network.fireClient("PlayerJoinedMatchPad", Player, OtherPlayer, matchPadEnum, teamIndex)
	end
	for matchPadEnum, matchPadStateEnum in MatchPadState do
		Network.fireClient("MatchPadStateChanged", Player, matchPadEnum, matchPadStateEnum)
	end
end
local function initializeMatchJoiningPads()
	SoccerDuelsServer = require(script.Parent)

	local MatchJoiningPadsFolder = Assets.getExpectedAsset("MatchJoiningPadsFolder")
	for _, Folder in MatchJoiningPadsFolder:GetChildren() do
		initializeMatchJoinPad(Folder)
	end

	Network.onServerInvokeConnect("PlayerJoinMatchPad", clientJoinMatchPad)
	Network.onServerInvokeConnect("PlayerDisconnectFromMatchPad", clientDisconnectFromMatchPad)
	Network.onServerInvokeConnect("TeleportPlayerToMatchPad", clientTeleportToMatchPad)

	-- workspace.TouchesUseCollisionGroups needs to be set to true for this optimization to work
	PhysicsService:RegisterCollisionGroup(LOBBY_DEVICE_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(LOBBY_DEVICE_COLLISION_GROUP, "Default", false)

	Utility.onCharacterLoadedConnect(playerCharacterLoaded)
	Utility.runServiceSteppedConnect(MATCH_JOINING_PAD_STATE_CHANGE_POLL_RATE_SECONDS, matchPadTimerTick)

	Network.onServerEventConnect("PlayerVoteForMap", clientVoteOnMap)
end

return {
	getMatchPadWinningMapVote = getMatchPadWinningMapVote,
	getMatchPadMapVotes = getMatchPadMapVotes,

	teleportPlayerToLobbySpawnLocation = teleportPlayerToLobbySpawnLocation,
	teleportPlayerToMatchPad = teleportPlayerToMatchPad,
	matchPadTimerTick = matchPadTimerTick,

	getPlayerConnectedMatchPadTeam = getPlayerConnectedMatchPadTeamIndex,
	getPlayerConnectedMatchPadName = getPlayerConnectedMatchPadName,
	getMatchPadTeamPlayers = getMatchPadTeamPlayers,
	getMatchJoiningPads = getMatchJoiningPads,
	getMatchPadState = getMatchPadState,

	playerCharacterLoaded = playerCharacterLoaded,
	initialize = initializeMatchJoiningPads,
	playerDataLoaded = onPlayerDataLoaded,
	disconnectPlayer = disconnectPlayer,
}
