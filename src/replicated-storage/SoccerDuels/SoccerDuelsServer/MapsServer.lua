-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)
local SoccerDuelsServer -- required in initialize()

-- const
local MAX_NUM_MAP_INSTANCES_PER_GRID_ROW = Config.getConstant("MaxMapInstancesPerGridRow")
local STUDS_BETWEEN_MAP_INSTANCES = Config.getConstant("DistanceBetweenMapInstancesStuds")

local MAP_STATE_TICK_RATE_SECONDS = Config.getConstant("MapStateTickRateSeconds")
local NUMBER_OF_MATCHES_PER_GAME = Config.getConstant("NumberOfMatchesPerGame")

local MAP_LOADING_DURATION_SECONDS = Config.getConstant("MapLoadingDurationSeconds")
local MATCH_COUNTDOWN_DURATION_SECONDS = Config.getConstant("MatchCountdownDurationSeconds")
local MATCH_GAMEPLAY_DURATION_SECONDS = Config.getConstant("MatchGameplayDurationSeconds")
local MATCH_OVER_DURATION_SECONDS = Config.getConstant("MatchOverDurationSeconds")
local GAME_OVER_DURATION_SECONDS = Config.getConstant("GameOverDurationSeconds")

local MAP_LOADING_STATE_ENUM = Enums.getEnum("MapState", "Loading")
local MATCH_COUNTDOWN_STATE_ENUM = Enums.getEnum("MapState", "MatchCountdown")
local MATCH_GAMEPLAY_STATE_ENUM = Enums.getEnum("MapState", "MatchGameplay")
local MATCH_OVER_STATE_ENUM = Enums.getEnum("MapState", "MatchOver")
local GAME_OVER_STATE_ENUM = Enums.getEnum("MapState", "GameOver")
local PERPETUAL_GAMEPLAY_STATE_ENUM = Enums.getEnum("MapState", "Gameplay")

local DEFAULT_MATCH_CYCLE_ENABLED = Config.getConstant("DefaultMapInstanceOptions", "MatchCycleEnabled")

-- var
local mapGridOrigin -- Vector3
local mapInstanceCounter = 0 -- int
local MapInstanceIdToMapPositionIndex = {} -- int mapInstanceId --> int mapPositionIndex
local MapInstanceFolder = {} -- int mapPositionIndex --> Folder
local MapInstancePlayers = {} -- int mapInstanceId --> { Player --> int teamIndex ( 1 or 2 ) }
local PlayerConnectedMapInstance = {} -- Player --> mapInstanceId

local MapInstanceState = {} -- int mapInstanceId --> int mapStateEnum
local MapInstanceStateChangeTimestamp = {} -- int mapInstanceId --> int unixTimestampMilliseconds
local MapInstanceMatchesPlayed = {} -- int mapInstanceId --> int numberOfMatchesPlayed
local MapInstanceMapEnum = {} -- int mapInstanceId --> int mapEnum

-- private
local function replicateMapStateToPlayer(Player)
	local mapStateEnum
	if PlayerConnectedMapInstance[Player] then
		mapStateEnum = MapInstanceState[PlayerConnectedMapInstance[Player]]
	end

	Network.fireClient("MapStateChanged", Player, mapStateEnum)
end

local destroyMapInstance
local function setMapState(mapInstanceId, mapStateEnum, durationSeconds)
	MapInstanceState[mapInstanceId] = mapStateEnum

	local stateChangeTimestamp
	if durationSeconds then
		stateChangeTimestamp = Time.getUnixTimestampMilliseconds() + 1E3 * durationSeconds
	end

	MapInstanceStateChangeTimestamp[mapInstanceId] = stateChangeTimestamp

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		replicateMapStateToPlayer(Player)
	end
end
local function mapInstanceHasNoPlayersOnATeam(mapInstanceId)
	local team1HasPlayers = false
	local team2HasPlayers = false

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		if teamIndex == 1 then
			team1HasPlayers = true
		else
			team2HasPlayers = true
		end

		if team1HasPlayers and team2HasPlayers then
			return false
		end
	end

	return not (team1HasPlayers and team2HasPlayers)
end
local function updateMapStateAfterPlayerLeft(mapInstanceId)
	-- if MatchCycleEnabled=false, we don't do anything
	if MapInstanceMatchesPlayed[mapInstanceId] == nil then
		return
	end

	-- 'MatchGameplay' --> 'MatchOver' when there are no players on a team
	local currentStateEnum = MapInstanceState[mapInstanceId]
	if currentStateEnum == MATCH_GAMEPLAY_STATE_ENUM then
		if not mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			return
		end

		setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
		return
	end
end
local function updateMapState(mapInstanceId)
	local currentStateEnum = MapInstanceState[mapInstanceId]
	local stateChangeTimestamp = MapInstanceStateChangeTimestamp[mapInstanceId]

	if stateChangeTimestamp == nil then
		return
	end

	local now = Time.getUnixTimestampMilliseconds()
	if now < stateChangeTimestamp then
		return
	end

	-- 'Loading' --> 'MatchCountdown' | 'Gameplay' (dependencing on MatchCycleEnabled)
	if currentStateEnum == MAP_LOADING_STATE_ENUM then
		-- MatchCycleEnabled=true
		if MapInstanceMatchesPlayed[mapInstanceId] then -- (interpret having a number of matches played as MatchCycleEnabled=true)
			setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
			return
		end

		-- MatchCycleEnabled=false
		setMapState(mapInstanceId, PERPETUAL_GAMEPLAY_STATE_ENUM, nil)
		return
	end

	-- 'MatchCountdown' --> 'MatchGameplay' | 'MatchOver' (if a team has no players on it)
	if currentStateEnum == MATCH_COUNTDOWN_STATE_ENUM then
		if mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
			return
		end

		setMapState(mapInstanceId, MATCH_GAMEPLAY_STATE_ENUM, MATCH_GAMEPLAY_DURATION_SECONDS)
		return
	end

	-- 'MatchGameplay' --> 'MatchOver'
	if currentStateEnum == MATCH_GAMEPLAY_STATE_ENUM then
		setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
		return
	end

	-- 'MatchOver' --> 'MatchCountdown' | 'GameOver'
	if currentStateEnum == MATCH_OVER_DURATION_SECONDS then
		-- go to 'GameOver' if we've played all of the matches
		MapInstanceMatchesPlayed[mapInstanceId] += 1
		if MapInstanceMatchesPlayed[mapInstanceId] >= NUMBER_OF_MATCHES_PER_GAME then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'GameOver' if a team has no players on it
		if mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'MatchCountdown' to repeat the oloop
		setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
		return
	end

	-- 'GameOver' --> nil (destroy the map)
	if currentStateEnum == GAME_OVER_STATE_ENUM then
		destroyMapInstance(mapInstanceId)
		return
	end
end

local function getNewMapId()
	mapInstanceCounter += 1
	return mapInstanceCounter
end
local function getUnusedMapPositionIndex()
	local mapPositionIndex = 0
	repeat
		mapPositionIndex += 1
	until MapInstanceFolder[mapPositionIndex] == nil

	return mapPositionIndex
end
local function mapPositionIndexToOriginPosition(mapPositionIndex)
	return mapGridOrigin
		+ Vector3.new(
				((mapPositionIndex - 1) % MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5,
				0,
				math.floor(mapPositionIndex / MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5
			)
			* STUDS_BETWEEN_MAP_INSTANCES
end

-- public
local function getMapInstanceState(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapStateEnum = MapInstanceState[mapInstanceId]
	if mapStateEnum == nil then
		return nil
	end

	return Enums.enumToName("MapState", mapStateEnum)
end
local function getPlayerTeamIndex(Player) -- TODO will probably want to make this work with match joining pads as well
	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	return MapInstancePlayers[mapInstanceId][Player]
end
local function mapTimerTick()
	for mapInstanceId, _ in MapInstanceStateChangeTimestamp do
		updateMapState(mapInstanceId)
	end
end

local function disconnectPlayerFromAllMapInstances(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	MapInstancePlayers[mapInstanceId][Player] = nil
	PlayerConnectedMapInstance[Player] = nil

	updateMapStateAfterPlayerLeft(mapInstanceId)
	replicateMapStateToPlayer(Player)
end
local function getPlayersConnectedToMapInstance(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return MapInstancePlayers[mapInstanceId]
end
local function getPlayerConnectedMapInstance(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return PlayerConnectedMapInstance[Player]
end
local function connectPlayerToMapInstance(Player, mapInstanceId, teamIndex)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		error(`{Player.Name}'s data is not loaded!`)
	end
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not an integer!`)
	end
	if MapInstanceIdToMapPositionIndex[mapInstanceId] == nil then
		error(`{mapInstanceId} is not an active map instance id!`)
	end
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	disconnectPlayerFromAllMapInstances(Player)

	MapInstancePlayers[mapInstanceId][Player] = teamIndex
	PlayerConnectedMapInstance[Player] = mapInstanceId

	replicateMapStateToPlayer(Player)
end
local function playerIsInLobby(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		return false
	end

	return PlayerConnectedMapInstance[Player] == nil
end

local function getMapInstanceMapName(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return Enums.enumToName("Map", MapInstanceMapEnum[mapInstanceId])
end
local function getMapInstanceFolder(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return nil
	end

	return MapInstanceFolder[mapPositionIndex]
end
local function getMapInstanceOrigin(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return nil
	end

	return mapPositionIndexToOriginPosition(mapPositionIndex)
end
function destroyMapInstance(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return
	end

	local MapFolder = MapInstanceFolder[mapPositionIndex]
	if MapFolder == nil then
		return
	end

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		disconnectPlayerFromAllMapInstances(Player)
	end

	MapFolder:Destroy()
	MapInstanceFolder[mapPositionIndex] = nil

	MapInstancePlayers[mapInstanceId] = nil
	MapInstanceIdToMapPositionIndex[mapInstanceId] = nil

	MapInstanceState[mapInstanceId] = nil
	MapInstanceStateChangeTimestamp[mapInstanceId] = nil
	MapInstanceMatchesPlayed[mapInstanceId] = nil
end
local function newMapInstance(mapName, Options)
	Options = Options or {}
	local mapEnum = Enums.getEnum("Map", mapName)

	if not (typeof(mapName) == "string") then
		error(`{mapName} is not a string!`)
	end
	if mapEnum == nil then
		error(`{mapName} is not a Map!`)
	end
	if not (typeof(Options) == "table") then
		error(`{Options} is not a table!`)
	end

	local MATCH_CYCLE_ENABLED = if Options.MatchCycleEnabled ~= nil
		then Options.MatchCycleEnabled
		else DEFAULT_MATCH_CYCLE_ENABLED

	if not (typeof(MATCH_CYCLE_ENABLED) == typeof(DEFAULT_MATCH_CYCLE_ENABLED)) then
		error(`{MATCH_CYCLE_ENABLED} is not a {typeof(DEFAULT_MATCH_CYCLE_ENABLED)}!`)
	end

	local mapInstanceId = getNewMapId() -- the mapInstanceId must never be reused so we can reliably check if a map instance has been destroyed
	local mapPositionIndex = getUnusedMapPositionIndex() -- but we can reuse the position placement of the map
	local mapOrigin = mapPositionIndexToOriginPosition(mapPositionIndex)

	local mapFolderAssetName = `{mapName} MapFolder`
	local mapOriginPartAssetName = `{mapName} MapOriginPart`

	local MapFolder = Assets.cloneExpectedAsset(mapFolderAssetName)
	local MapOriginPart = Assets.getExpectedAsset(mapOriginPartAssetName, mapFolderAssetName, MapFolder)

	MapFolder.PrimaryPart = MapOriginPart
	MapFolder:PivotTo(CFrame.new(mapOrigin))
	MapFolder.Parent = workspace

	MapInstanceFolder[mapPositionIndex] = MapFolder
	MapInstancePlayers[mapInstanceId] = {}
	MapInstanceIdToMapPositionIndex[mapInstanceId] = mapPositionIndex
	MapInstanceMapEnum[mapInstanceId] = mapEnum

	if MATCH_CYCLE_ENABLED then
		MapInstanceMatchesPlayed[mapInstanceId] = 0
	end

	setMapState(mapInstanceId, MAP_LOADING_STATE_ENUM, MAP_LOADING_DURATION_SECONDS)

	return mapInstanceId
end

local function getAllMapInstances()
	local MapInstanceIds = {}

	for mapInstanceId, _ in MapInstanceIdToMapPositionIndex do
		table.insert(MapInstanceIds, mapInstanceId)
	end

	return MapInstanceIds
end
local function destroyAllMapInstances()
	for mapInstanceId, _ in MapInstanceIdToMapPositionIndex do
		destroyMapInstance(mapInstanceId)
	end
end

local function initializeMapsServer()
	SoccerDuelsServer = require(script.Parent)

	local MapGridOriginPart = Assets.getExpectedAsset("MapGridOriginPart")
	mapGridOrigin = MapGridOriginPart.Position

	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		Utility.convertInstanceIntoModel(Assets.getExpectedAsset(`{mapName} MapFolder`))
	end

	Utility.runServiceSteppedConnect(MAP_STATE_TICK_RATE_SECONDS, mapTimerTick)
end

return {
	-- map state
	getMapInstanceState = getMapInstanceState,
	getPlayerTeamIndex = getPlayerTeamIndex,
	mapTimerTick = mapTimerTick,

	-- map instances
	disconnectPlayerFromAllMapInstances = disconnectPlayerFromAllMapInstances,
	getPlayersConnectedToMapInstance = getPlayersConnectedToMapInstance,
	getPlayerConnectedMapInstance = getPlayerConnectedMapInstance,
	connectPlayerToMapInstance = connectPlayerToMapInstance,
	playerIsInLobby = playerIsInLobby, --> TODO this should probably be defined in the SoccerDuelsServer module

	destroyAllMapInstances = destroyAllMapInstances,
	getAllMapInstances = getAllMapInstances,

	getMapInstanceMapName = getMapInstanceMapName,
	getMapInstanceFolder = getMapInstanceFolder,
	getMapInstanceOrigin = getMapInstanceOrigin,
	destroyMapInstance = destroyMapInstance,
	newMapInstance = newMapInstance,

	-- standard methods
	disconnectPlayer = disconnectPlayerFromAllMapInstances, -- this is invoked in SoccerDuelsServer.disconnectPlayer(), hence the duplicate method
	initialize = initializeMapsServer,
}
