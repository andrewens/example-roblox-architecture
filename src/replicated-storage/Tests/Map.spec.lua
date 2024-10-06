-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- private
local function makeSomePlayersConnectToAMap(numPlayers, mapId)
	if not Utility.isInteger(numPlayers) then
		error(`{numPlayers} is not an integer!`)
	end
	if mapId == nil then
		error(`{mapId} is not a map id!`)
	end

	local Clients = {}

	for i = 1, numPlayers do
		local Player = MockInstance.new("Player")
		local Client = SoccerDuels.newClient(Player)
		Client:LoadPlayerDataAsync()
		Clients[i] = Client

		SoccerDuels.connectPlayerToMapInstance(Player, mapId, (i % 2) + 1)
	end

	return table.unpack(Clients)
end

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
		describe("SoccerDuels.connectPlayerToMapInstance()", function()
			it("Connects a player to one map instance at a time", function()
				SoccerDuels.destroyAllMapInstances()
				SoccerDuels.disconnectAllPlayers()

				local mapId1 = SoccerDuels.newMapInstance("Stadium")
				local mapId2 = SoccerDuels.newMapInstance("Map2")

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)

				local s = pcall(SoccerDuels.connectPlayerToMapInstance, Player1, mapId1, 1)
				assert(not s)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()

				local BAD_INPUTS = {
					{ "Not a player", mapId1, 1 },
					{ Player1, "not a map instance", 1 },
					{ Player1, mapId1, "not a team index" },
				}

				for i, BadInputArgs in BAD_INPUTS do
					s = pcall(SoccerDuels.connectPlayerToMapInstance, table.unpack(BadInputArgs))
					if s then
						error(
							`SoccerDuels.connectPlayerToMapInstance() failed to throw error (bad input test case #{i})`
						)
					end
				end

				local Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				local Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Utility.tableCount(Map1Players) == 0)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == nil)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == 1)
				assert(Map2Players[Player1] == nil)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == nil)

				assert(Utility.tableCount(Map1Players) == 1)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(not SoccerDuels.playerIsInLobby(Player1))
				assert(SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == mapId1)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				SoccerDuels.connectPlayerToMapInstance(Player1, mapId2, 2)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == nil)
				assert(Map2Players[Player1] == 2)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == nil)

				assert(Utility.tableCount(Map1Players) == 0)
				assert(Utility.tableCount(Map2Players) == 1)

				assert(not SoccerDuels.playerIsInLobby(Player1))
				assert(SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == mapId2)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				SoccerDuels.connectPlayerToMapInstance(Player2, mapId2, 1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == nil)
				assert(Map2Players[Player1] == 2)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == 1)

				assert(Utility.tableCount(Map1Players) == 0)
				assert(Utility.tableCount(Map2Players) == 2)

				assert(not SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == mapId2)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == mapId2)

				SoccerDuels.disconnectPlayerFromAllMapInstances(Player1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == nil)
				assert(Map2Players[Player1] == nil)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == 1)

				assert(Utility.tableCount(Map1Players) == 0)
				assert(Utility.tableCount(Map2Players) == 1)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == nil)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == mapId2)

				SoccerDuels.disconnectPlayer(Player2)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == nil)
				assert(Map2Players[Player1] == nil)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == nil)

				assert(Utility.tableCount(Map1Players) == 0)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2)) -- still not in lobby tho
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == nil)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				s = pcall(SoccerDuels.connectPlayerToMapInstance, Player2, mapId1, 1)
				assert(not s)

				SoccerDuels.connectPlayerToMapInstance(Player1, mapId1, 1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players[Player1] == 1)
				assert(Map2Players[Player1] == nil)
				assert(Map1Players[Player2] == nil)
				assert(Map2Players[Player2] == nil)

				assert(Utility.tableCount(Map1Players) == 1)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(not SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == mapId1)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				SoccerDuels.destroyMapInstance(mapId1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players == nil)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == nil)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				Client1:Destroy()
				Client2:Destroy()

				SoccerDuels.destroyAllMapInstances()
			end)
		end)
		describe("Map match state", function()
			--[[
				Loading
					|
				MatchCountdown
					|
				Match---------->--------|
					|					|
				MatchOver				|
					|					|
					|---------->--------|
					|					|
				repeat 5x		If all players on a team leave
					|					|
					|---------<---------|
					|
				GameOver
					|
				(destroy Map)
			]]
			--[[
				Additional states:
				* WinningTeamIndex
				* Goals per team
				* Time left
				* Players per team
			]]
			it("Maps begin in a 'Loading' state that lasts a fixed amount of time", function()
				SoccerDuels.destroyAllMapInstances()
				SoccerDuels.resetTestingVariables()

				local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
				local maxError = 0.010

				local mapId = SoccerDuels.newMapInstance("Stadium")

				assert(SoccerDuels.getMapInstanceState(mapId) == "Loading")

				SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration - maxError)
				SoccerDuels.mapTimerTick()

				assert(SoccerDuels.getMapInstanceState(mapId) == "Loading")

				SoccerDuels.addExtraSecondsForTesting(2 * maxError)
				SoccerDuels.mapTimerTick()

				assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

				SoccerDuels.destroyMapInstance(mapId)

				assert(SoccerDuels.getMapInstanceState(mapId) == nil)
			end)
			it(
				"Maps repeat a cycle of 'MatchCountdown', 'MatchGameplay', and 'MatchOver' states a few times, then it's a 'GameOver' state",
				function()
					SoccerDuels.destroyAllMapInstances()
					SoccerDuels.resetTestingVariables()

					local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
					local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
					local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
					local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
					local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
					local maxError = 0.010

					local numMatchesPerGame = SoccerDuels.getConstant("NumberOfMatchesPerGame")

					local mapId = SoccerDuels.newMapInstance("Stadium")
					local Client1, Client2 = makeSomePlayersConnectToAMap(2, mapId)

					SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
					SoccerDuels.mapTimerTick()

					for i = 1, numMatchesPerGame do
						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration - maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(2 * maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

						SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration - maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

						SoccerDuels.addExtraSecondsForTesting(2 * maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.addExtraSecondsForTesting(matchOverDuration - maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.addExtraSecondsForTesting(2 * maxError)
						SoccerDuels.mapTimerTick()
					end

					assert(SoccerDuels.getMapInstanceState(mapId) == "GameOver")
					assert(SoccerDuels.getMapInstanceFolder(mapId))

					SoccerDuels.addExtraSecondsForTesting(gameOverDuration - maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "GameOver")
					assert(SoccerDuels.getMapInstanceFolder(mapId))

					SoccerDuels.addExtraSecondsForTesting(2 * maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == nil) -- it automatically gets destroyed
					assert(SoccerDuels.getMapInstanceFolder(mapId) == nil)

					Client1:Destroy()
					Client2:Destroy()
				end
			)
			it(
				"When creating a map, you can specify to skip the match cycle and remain in a perpetual 'Gameplay' state",
				function()
					SoccerDuels.destroyAllMapInstances()
					SoccerDuels.resetTestingVariables()

					local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
					local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
					local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
					local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
					local maxError = 0.010

					local numMatchesPerGame = SoccerDuels.getConstant("NumberOfMatchesPerGame")

					local mapId = SoccerDuels.newMapInstance("Stadium", {
						MatchCycleEnabled = false,
						-- in this mode, the map doesn't go away or end or anything if there are no players on a team
					})

					assert(SoccerDuels.getMapInstanceState(mapId) == "Loading")

					SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "Gameplay")

					SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "Gameplay")

					SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "Gameplay")

					SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "Gameplay")

					SoccerDuels.destroyMapInstance(mapId)

					assert(SoccerDuels.getMapInstanceState(mapId) == nil)
				end
			)
			describe(
				"If, because they all left, a team has no players during 'MatchGameplay', map state goes directly to 'MatchOver', then 'GameOver'",
				function()
					it("Players left during 'MatchGameplay'", function()
						SoccerDuels.destroyAllMapInstances()
						SoccerDuels.resetTestingVariables()

						local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
						local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
						local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
						local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
						local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
						local maxError = 0.010

						local mapId = SoccerDuels.newMapInstance("Stadium")
						local Client1, Client2, Client3, Client4 = makeSomePlayersConnectToAMap(4, mapId)

						assert(
							SoccerDuels.getPlayerTeamIndex(Client1.Player)
								== SoccerDuels.getPlayerTeamIndex(Client3.Player)
						)

						SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

						SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration * 0.5) -- this is just an arbitrary time during match gameplay
						SoccerDuels.mapTimerTick()
						SoccerDuels.disconnectPlayer(Client1.Player)

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

						SoccerDuels.disconnectPlayer(Client3.Player) -- Client3 and Client1 need to be on the same team so we can get rid of all players on one team

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						if not (SoccerDuels.getMapInstanceState(mapId) == "GameOver") then
							error(`{SoccerDuels.getMapInstanceState(mapId)} != "GameOver"`)
						end

						SoccerDuels.addExtraSecondsForTesting(gameOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == nil)

						Client1:Destroy()
						Client2:Destroy()
						Client3:Destroy()
						Client4:Destroy()
					end)
					it("Players left during 'MatchCountdown'", function()
						SoccerDuels.destroyAllMapInstances()
						SoccerDuels.resetTestingVariables()

						local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
						local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
						local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
						local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
						local maxError = 0.010

						local mapId = SoccerDuels.newMapInstance("Stadium")
						local Client1, Client2, Client3, Client4 = makeSomePlayersConnectToAMap(4, mapId)

						assert(
							SoccerDuels.getPlayerTeamIndex(Client1.Player)
								== SoccerDuels.getPlayerTeamIndex(Client3.Player)
						) -- Client3 and Client1 need to be on the same team so we can get rid of all players on one team

						SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(0.5 * matchCountdownDuration) -- this is just an arbitrary time during match gameplay
						SoccerDuels.mapTimerTick()

						SoccerDuels.disconnectPlayer(Client1.Player)

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.disconnectPlayer(Client3.Player)
						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(0.5 * matchCountdownDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						if not (SoccerDuels.getMapInstanceState(mapId) == "GameOver") then
							error(`{SoccerDuels.getMapInstanceState(mapId)} != "GameOver"`)
						end

						SoccerDuels.addExtraSecondsForTesting(gameOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == nil)

						Client1:Destroy()
						Client2:Destroy()
						Client3:Destroy()
						Client4:Destroy()
					end)
					it("Players left during 'MatchOver'", function()
						SoccerDuels.destroyAllMapInstances()
						SoccerDuels.resetTestingVariables()

						local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
						local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
						local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
						local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
						local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
						local maxError = 0.010

						local mapId = SoccerDuels.newMapInstance("Stadium")
						local Client1, Client2, Client3, Client4 = makeSomePlayersConnectToAMap(4, mapId)

						assert(
							SoccerDuels.getPlayerTeamIndex(Client1.Player)
								== SoccerDuels.getPlayerTeamIndex(Client3.Player)
						) -- Client3 and Client1 need to be on the same team so we can get rid of all players on one team

						SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

						SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

						SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.addExtraSecondsForTesting(0.5 * matchOverDuration)
						SoccerDuels.mapTimerTick()

						SoccerDuels.disconnectPlayer(Client1.Player)

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")

						SoccerDuels.disconnectPlayerFromAllMapInstances(Client3.Player)

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver") -- 'MatchOver' lasts for as long as it lasts still

						SoccerDuels.addExtraSecondsForTesting(0.5 * matchOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						if not (SoccerDuels.getMapInstanceState(mapId) == "GameOver") then
							error(`{SoccerDuels.getMapInstanceState(mapId)} != "GameOver"`)
						end

						SoccerDuels.addExtraSecondsForTesting(gameOverDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == nil)

						Client1:Destroy()
						Client2:Destroy()
						Client3:Destroy()
						Client4:Destroy()
					end)
				end
			)
		end)
	end)
end
