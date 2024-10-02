-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("Maps", function()
		describe("SoccerDuels.createMap()", function()
			it("Clones a given map folder into workspace, positioned on a grid", function()
				-- must pass a valid map name
				local BAD_INPUTS = {
					"This is not the name of a map",
					nil,
					5230492304,
				}

				for i, badMapName in BAD_INPUTS do
					local s = pcall(SoccerDuels.newMapInstance, badMapName)
					if s then
						error(`SoccerDuels.createMap() failed to throw for bad input #{i}: {badMapName}`)
					end
				end

				-- must copy maps into a grid in workspace
				local mapGridOrigin = SoccerDuels.getExpectedAsset("MapGridOriginPart").Position
				local maxNumberOfMapsPerGridRow = SoccerDuels.getConstant("MaxMapInstancesPerGridRow")
				local studsBetweenMapInstances = SoccerDuels.getConstant("DistanceBetweenMapInstancesStuds")

				local i = 0
				local j = 0
				local MapIds = {} -- int mapInstanceId --> true

				for mapEnum, mapName in SoccerDuels.iterateEnumsOfType("Map") do
					-- must generate a unique id
					local mapInstanceId = SoccerDuels.newMapInstance(mapName)

					assert(MapIds[mapInstanceId] == nil)
					MapIds[mapInstanceId] = true

					-- must place map on a grid
					local mapOrigin = SoccerDuels.getMapInstanceOrigin(mapInstanceId)
					local correctMapOrigin = mapGridOrigin + Vector3.new(i + 0.5, 0, j + 0.5) * studsBetweenMapInstances

					if not (mapOrigin:FuzzyEq(correctMapOrigin)) then
						error(`{mapOrigin} != {correctMapOrigin} (mapInstanceId={mapInstanceId})`)
					end

					-- must copy map into workspace
					local mapAssetName = `{mapName} MapFolder`
					local mapOriginPartAssetName = `{mapName} MapOriginPart`

					local MapTemplate = SoccerDuels.getExpectedAsset(mapAssetName)
					local MapFolder = SoccerDuels.getMapInstanceFolder(mapInstanceId)
					local MapOriginPart = SoccerDuels.getExpectedAsset(mapOriginPartAssetName, mapAssetName, MapFolder)

					assert(MapFolder.ClassName == MapTemplate.ClassName)
					assert(MapFolder.Parent == workspace)
					if not (MapOriginPart.Position:FuzzyEq(mapOrigin)) then
						error(`{mapOrigin} != {MapOriginPart.Position} (mapInstanceId={mapInstanceId})`)
					end

					-- keep track of grid indices
					i += 1
					if i > maxNumberOfMapsPerGridRow then
						i = 0
						j += 1
					end
				end

				for mapInstanceId, _ in MapIds do
					SoccerDuels.destroyMapInstance(mapInstanceId)

					assert(SoccerDuels.getMapInstanceFolder(mapInstanceId) == nil)
				end
			end)
		end)
		describe("SoccerDuels.getAllMapInstances()", function()
			it("Returns a table of every active mapInstanceId", function()
				SoccerDuels.destroyAllMapInstances()

				local mapId1 = SoccerDuels.newMapInstance("Stadium")
				local mapId2 = SoccerDuels.newMapInstance("Stadium")
				local mapId3 = SoccerDuels.newMapInstance("Map2")

				local AllMapIds = SoccerDuels.getAllMapInstances()
				assert(#AllMapIds == 3)
				assert(Utility.tableContainsValue(AllMapIds, mapId1))
				assert(Utility.tableContainsValue(AllMapIds, mapId2))
				assert(Utility.tableContainsValue(AllMapIds, mapId3))

				SoccerDuels.destroyMapInstance(mapId2)

				AllMapIds = SoccerDuels.getAllMapInstances()
				assert(#AllMapIds == 2)
				assert(Utility.tableContainsValue(AllMapIds, mapId1))
				assert(Utility.tableContainsValue(AllMapIds, mapId3))

				SoccerDuels.destroyAllMapInstances()

				AllMapIds = SoccerDuels.getAllMapInstances()
				assert(#AllMapIds == 0)
			end)
		end)
	end)
end
