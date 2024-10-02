-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)
local SoccerDuelsServer -- required in initialize()

-- const
local MAX_NUM_MAP_INSTANCES_PER_GRID_ROW = Config.getConstant("MaxMapInstancesPerGridRow")
local STUDS_BETWEEN_MAP_INSTANCES = Config.getConstant("DistanceBetweenMapInstancesStuds")

-- var
local mapGridOrigin
local MapInstanceFolder = {} -- int mapInstanceId --> Folder
local MapInstancePlayers = {} -- int mapInstanceId --> { Player --> int teamIndex ( 1 or 2 ) }
local PlayerConnectedMapInstance = {} -- Player --> mapInstanceId

-- private
local function getUnusedMapInstanceId()
	local mapInstanceId = 0
	repeat
		mapInstanceId += 1
	until MapInstanceFolder[mapInstanceId] == nil

	return mapInstanceId
end
local function mapInstanceIdToOriginPosition(mapInstanceId)
	return mapGridOrigin
		+ Vector3.new(
				((mapInstanceId - 1) % MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5,
				0,
				math.floor(mapInstanceId / MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5
			)
			* STUDS_BETWEEN_MAP_INSTANCES
end

-- public
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
	if MapInstanceFolder[mapInstanceId] == nil then
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

	return MapInstanceFolder[mapInstanceId]
end
local function getMapInstanceOrigin(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return mapInstanceIdToOriginPosition(mapInstanceId)
end
local function destroyMapInstance(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local MapFolder = MapInstanceFolder[mapInstanceId]
	if MapFolder == nil then
		return
	end

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		disconnectPlayerFromAllMapInstances(Player)
	end

	MapFolder:Destroy()
	MapInstanceFolder[mapInstanceId] = nil
	MapInstancePlayers[mapInstanceId] = nil
end
local function newMapInstance(mapName)
	if not (typeof(mapName) == "string") then
		error(`{mapName} is not a string!`)
	end
	if Enums.getEnum("Map", mapName) == nil then
		error(`{mapName} is not a Map!`)
	end

	local mapInstanceId = getUnusedMapInstanceId()
	local mapOrigin = mapInstanceIdToOriginPosition(mapInstanceId)

	local mapFolderAssetName = `{mapName} MapFolder`
	local mapOriginPartAssetName = `{mapName} MapOriginPart`

	local MapFolder = Assets.cloneExpectedAsset(mapFolderAssetName)
	local MapOriginPart = Assets.getExpectedAsset(mapOriginPartAssetName, mapFolderAssetName, MapFolder)

	MapFolder.PrimaryPart = MapOriginPart
	MapFolder:PivotTo(CFrame.new(mapOrigin))
	MapFolder.Parent = workspace

	MapInstanceFolder[mapInstanceId] = MapFolder
	MapInstancePlayers[mapInstanceId] = {}

	return mapInstanceId
end
local function getAllMapInstances()
	local MapInstanceIds = {}

	for mapInstanceId, _ in MapInstanceFolder do
		table.insert(MapInstanceIds, mapInstanceId)
	end

	return MapInstanceIds
end
local function destroyAllMapInstances()
	for mapInstanceId, _ in MapInstanceFolder do
		destroyMapInstance(mapInstanceId)
	end
end
local function initializeMapsServer()
	SoccerDuelsServer = require(script.Parent)

	local MapGridOriginPart = Assets.getExpectedAsset("MapGridOriginPart")
	mapGridOrigin = MapGridOriginPart.Position

	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		local MapFolder = Assets.getExpectedAsset(`{mapName} MapFolder`)
		Utility.convertInstanceIntoModel(MapFolder)
	end
end

return {
	disconnectPlayerFromAllMapInstances = disconnectPlayerFromAllMapInstances,
	getPlayersConnectedToMapInstance = getPlayersConnectedToMapInstance,
	getPlayerConnectedMapInstance = getPlayerConnectedMapInstance,
	connectPlayerToMapInstance = connectPlayerToMapInstance,
	playerIsInLobby = playerIsInLobby,

	destroyAllMapInstances = destroyAllMapInstances,
	getMapInstanceFolder = getMapInstanceFolder,
	getMapInstanceOrigin = getMapInstanceOrigin,
	destroyMapInstance = destroyMapInstance,
	getAllMapInstances = getAllMapInstances,
	newMapInstance = newMapInstance,

	disconnectPlayer = disconnectPlayerFromAllMapInstances, -- this is invoked in SoccerDuelsServer.disconnectPlayer(), hence the duplicate method
	initialize = initializeMapsServer,
}
