-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local MAX_NUM_MAP_INSTANCES_PER_GRID_ROW = Config.getConstant("MaxMapInstancesPerGridRow")
local STUDS_BETWEEN_MAP_INSTANCES = Config.getConstant("DistanceBetweenMapInstancesStuds")

-- var
local mapGridOrigin
local MapInstanceFolder = {} -- int mapInstanceId --> Folder

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

	return mapInstanceId
end
local function initializeMapsServer()
	local MapGridOriginPart = Assets.getExpectedAsset("MapGridOriginPart")
	mapGridOrigin = MapGridOriginPart.Position

	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		local MapFolder = Assets.getExpectedAsset(`{mapName} MapFolder`)
		Utility.convertInstanceIntoModel(MapFolder)
	end
end

return {
	getMapInstanceFolder = getMapInstanceFolder,
	getMapInstanceOrigin = getMapInstanceOrigin,
	newMapInstance = newMapInstance,

	initialize = initializeMapsServer,
}
