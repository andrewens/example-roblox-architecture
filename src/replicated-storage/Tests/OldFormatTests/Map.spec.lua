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

		SoccerDuels.connectPlayerToMapInstance(Player, mapId, ((i - 1) % 2) + 1)
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

				assert(Client1:GetConnectedMapFolder() == nil)
				assert(Client2:GetConnectedMapFolder() == nil)

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

				assert(Client1:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId1))
				assert(Client2:GetConnectedMapFolder() == nil)

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

				assert(Client1:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId2))
				assert(Client2:GetConnectedMapFolder() == nil)

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

				assert(Client1:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId2))
				assert(Client2:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId2))

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

				assert(Client1:GetConnectedMapFolder() == nil)
				assert(Client2:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId2))

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

				assert(Client1:GetConnectedMapFolder() == nil)
				assert(Client2:GetConnectedMapFolder() == nil)

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

				assert(Client1:GetConnectedMapFolder() == SoccerDuels.getMapInstanceFolder(mapId1))
				assert(Client2:GetConnectedMapFolder() == nil)

				SoccerDuels.destroyMapInstance(mapId1)
				Map1Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId1)
				Map2Players = SoccerDuels.getPlayersConnectedToMapInstance(mapId2)

				assert(Map1Players == nil)
				assert(Utility.tableCount(Map2Players) == 0)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player1) == nil)
				assert(SoccerDuels.getPlayerConnectedMapInstance(Player2) == nil)

				assert(Client1:GetConnectedMapFolder() == nil)
				assert(Client2:GetConnectedMapFolder() == nil)

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
				GoalCutscene (only if someone scored)
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
				"Maps repeat a cycle of 'MatchCountdown', 'MatchGameplay', 'MatchOver', and states a few times, then it's a 'GameOver' state",
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
			it("Players in a map are automatically returned to the lobby when the map is destroyed", function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.destroyAllMapInstances()
				SoccerDuels.resetTestingVariables()

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)

				Client1:LoadPlayerDataAsync()
				Client2:LoadPlayerDataAsync()

				local mapId = SoccerDuels.newMapInstance("Stadium")

				SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 1)
				SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 2)

				assert(SoccerDuels.getMapInstanceState(mapId) == "Loading")
				assert(not SoccerDuels.playerIsInLobby(Player1))
				assert(not SoccerDuels.playerIsInLobby(Player2))

				SoccerDuels.destroyMapInstance(mapId)

				assert(SoccerDuels.playerIsInLobby(Player1))
				assert(SoccerDuels.playerIsInLobby(Player2))

				assert(Client1:GetUserInterfaceMode() == "Lobby")
				assert(Client2:GetUserInterfaceMode() == "Lobby")

				Client1:Destroy()
				Client2:Destroy()
			end)
			it(
				"If a player scores a goal during 'MatchGameplay', then map state goes directly to 'MatchOver', then to 'GoalCutscene'",
				function()
					SoccerDuels.destroyAllMapInstances()
					SoccerDuels.resetTestingVariables()

					local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
					local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
					local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
					local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
					local goalCutsceneDuration = SoccerDuels.getConstant("GoalCutsceneDurationSeconds")
					local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
					local maxError = 0.010

					-- load map
					local mapId = SoccerDuels.newMapInstance("Stadium")
					local Client1, Client2 = makeSomePlayersConnectToAMap(2, mapId)

					SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

					SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
					SoccerDuels.mapTimerTick()

					-- one player scores goal
					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

					SoccerDuels.playerScoredGoal(Client1.Player)

					local team1Score, team2Score = SoccerDuels.getMapInstanceScore(mapId)

					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")
					assert(SoccerDuels.getPlayerThatScoredLastGoal(mapId) == Client1.Player)
					if not (team1Score == 1) then
						error(`{team1Score} != 1`)
					end
					assert(team2Score == 0)
					assert(SoccerDuels.getMapInstanceWinningTeam(mapId) == 1)

					-- if somehow a second goal is scored, only the first is counted
					SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "GoalCutscene")

					SoccerDuels.addExtraSecondsForTesting(goalCutsceneDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")

					SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")

					SoccerDuels.playerScoredGoal(Client2.Player)
					SoccerDuels.playerScoredGoal(Client1.Player)

					team1Score, team2Score = SoccerDuels.getMapInstanceScore(mapId)

					assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")
					assert(SoccerDuels.getPlayerThatScoredLastGoal(mapId) == Client2.Player)
					if not (team1Score == 1) then
						error(`{team1Score} != 1`)
					end
					assert(team2Score == 1)
					assert(SoccerDuels.getMapInstanceWinningTeam(mapId) == nil)

					-- cleanup
					SoccerDuels.destroyMapInstance(mapId)
					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
		describe("Player characters during a match", function()
			it(
				"Players have no characters during the 'Loading', 'GoalCutscene' or 'GameOver' states; characters are frozen during 'MatchCountdown', but not during 'MatchGameplay'; characters are teleported to starting positions for 'MatchCountdown'",
				function()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.destroyAllMapInstances()
					SoccerDuels.resetTestingVariables()

					local maxError = 0.010
					local mapLoadingDuration = SoccerDuels.getConstant("MapLoadingDurationSeconds")
					local matchCountdownDuration = SoccerDuels.getConstant("MatchCountdownDurationSeconds")
					local matchGameplayDuration = SoccerDuels.getConstant("MatchGameplayDurationSeconds")
					local matchOverDuration = SoccerDuels.getConstant("MatchOverDurationSeconds")
					local goalCutsceneDuration = SoccerDuels.getConstant("GoalCutsceneDurationSeconds")
					local gameOverDuration = SoccerDuels.getConstant("GameOverDurationSeconds")
					local numMatchesPerGame = SoccerDuels.getConstant("NumberOfMatchesPerGame")

					local lobbySpawnLocation = SoccerDuels.getExpectedAsset("LobbySpawnLocation").Position

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					assert(Player1.Character)
					assert(Player2.Character)
					assert(Utility.playerCharacterIsWithinDistanceOfPoint(Player1, lobbySpawnLocation, 10))
					assert(Utility.playerCharacterIsWithinDistanceOfPoint(Player2, lobbySpawnLocation, 10))

					local mapId = SoccerDuels.newMapInstance("Stadium")

					SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 1)
					SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 2)

					assert(SoccerDuels.getMapInstanceState(mapId) == "Loading")
					assert(Player1.Character == nil or Player1.Character.Parent == nil)
					assert(Player2.Character == nil or Player2.Character.Parent == nil)

					SoccerDuels.addExtraSecondsForTesting(mapLoadingDuration + maxError)
					SoccerDuels.mapTimerTick()

					for i = 1, numMatchesPerGame do
						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchCountdown")
						assert(Player1.Character.Parent)
						assert(Player2.Character.Parent)
						assert(Player1.Character.HumanoidRootPart.Anchored)
						assert(Player2.Character.HumanoidRootPart.Anchored)

						local startPosition1 = SoccerDuels.getMapInstanceStartingLocation(mapId, 1, 1) -- (teamIndex, teamPositionIndex)
						local startPosition2 = SoccerDuels.getMapInstanceStartingLocation(mapId, 2, 1)

						assert(Player1.Character.HumanoidRootPart.Position:FuzzyEq(startPosition1))
						assert(Player2.Character.HumanoidRootPart.Position:FuzzyEq(startPosition2))
						assert(not Utility.playerCharacterIsWithinDistanceOfPoint(Player1, lobbySpawnLocation, 10))
						assert(not Utility.playerCharacterIsWithinDistanceOfPoint(Player2, lobbySpawnLocation, 10))

						SoccerDuels.addExtraSecondsForTesting(matchCountdownDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchGameplay")
						assert(not Player1.Character.HumanoidRootPart.Anchored)
						assert(not Player2.Character.HumanoidRootPart.Anchored)

						Player1.Character:MoveTo(startPosition2) -- move characters off their starting positions
						Player2.Character:MoveTo(startPosition1)

						if i == 1 then
							SoccerDuels.playerScoredGoal(Player1)

							assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")
							assert(not Player1.Character.HumanoidRootPart.Anchored)
							assert(not Player2.Character.HumanoidRootPart.Anchored)

							SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
							SoccerDuels.mapTimerTick()

							assert(SoccerDuels.getMapInstanceState(mapId) == "GoalCutscene")
							assert(Player1.Character == nil or Player1.Character.Parent == nil)
							assert(Player2.Character == nil or Player2.Character.Parent == nil)

							SoccerDuels.addExtraSecondsForTesting(goalCutsceneDuration + maxError)
							SoccerDuels.mapTimerTick()

							continue
						end

						SoccerDuels.addExtraSecondsForTesting(matchGameplayDuration + maxError)
						SoccerDuels.mapTimerTick()

						assert(SoccerDuels.getMapInstanceState(mapId) == "MatchOver")
						assert(not Player1.Character.HumanoidRootPart.Anchored)
						assert(not Player2.Character.HumanoidRootPart.Anchored)

						SoccerDuels.addExtraSecondsForTesting(matchOverDuration + maxError)
						SoccerDuels.mapTimerTick()
					end

					assert(SoccerDuels.getMapInstanceState(mapId) == "GameOver")
					assert(Player1.Character == nil or Player1.Character.Parent == nil)
					assert(Player2.Character == nil or Player2.Character.Parent == nil)

					SoccerDuels.addExtraSecondsForTesting(gameOverDuration + maxError)
					SoccerDuels.mapTimerTick()

					assert(SoccerDuels.getMapInstanceState(mapId) == nil)
					assert(Player1.Character.Parent)
					assert(Player2.Character.Parent)
					assert(Utility.playerCharacterIsWithinDistanceOfPoint(Player1, lobbySpawnLocation, 10))
					assert(Utility.playerCharacterIsWithinDistanceOfPoint(Player2, lobbySpawnLocation, 10))

					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
	end)
end
