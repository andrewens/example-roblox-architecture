-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)
local Time = require(SoccerDuelsModule.Time)
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

-- private
local destroyMapInstance
local function setMapState(mapInstanceId, mapStateEnum, durationSeconds)
	MapInstanceState[mapInstanceId] = mapStateEnum

	local stateChangeTimestamp
	if durationSeconds then
		stateChangeTimestamp = Time.getUnixTimestampMilliseconds() + 1E3 * durationSeconds
	end

	MapInstanceStateChangeTimestamp[mapInstanceId] = stateChangeTimestamp
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

	-- 'Loading' --> 'MatchCountdown'
	if currentStateEnum == MAP_LOADING_STATE_ENUM then
		setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
		return
	end

	-- 'MatchCountdown' --> 'MatchGameplay'
	if currentStateEnum == MATCH_COUNTDOWN_STATE_ENUM then
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
		MapInstanceMatchesPlayed[mapInstanceId] += 1

		if MapInstanceMatchesPlayed[mapInstanceId] >= NUMBER_OF_MATCHES_PER_GAME then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

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
local function mapTimerTick()
	for mapInstanceId, mapStateEnum in MapInstanceState do
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
local function newMapInstance(mapName)
	if not (typeof(mapName) == "string") then
		error(`{mapName} is not a string!`)
	end
	if Enums.getEnum("Map", mapName) == nil then
		error(`{mapName} is not a Map!`)
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

	MapInstanceMatchesPlayed[mapInstanceId] = 0
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
	mapTimerTick = mapTimerTick,

	-- map instances
	disconnectPlayerFromAllMapInstances = disconnectPlayerFromAllMapInstances,
	getPlayersConnectedToMapInstance = getPlayersConnectedToMapInstance,
	getPlayerConnectedMapInstance = getPlayerConnectedMapInstance,
	connectPlayerToMapInstance = connectPlayerToMapInstance,
	playerIsInLobby = playerIsInLobby, --> TODO this should probably be defined in the SoccerDuelsServer module

	destroyAllMapInstances = destroyAllMapInstances,
	getMapInstanceFolder = getMapInstanceFolder,
	getMapInstanceOrigin = getMapInstanceOrigin,
	destroyMapInstance = destroyMapInstance,
	getAllMapInstances = getAllMapInstances,
	newMapInstance = newMapInstance,

	-- standard methods
	disconnectPlayer = disconnectPlayerFromAllMapInstances, -- this is invoked in SoccerDuelsServer.disconnectPlayer(), hence the duplicate method
	initialize = initializeMapsServer,
}
