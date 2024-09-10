-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = script:FindFirstAncestor("Tests")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("SoccerDuels database", function()
		describe("Client:LoadPlayerDataAsync()", function()
			it(
				"Loads the user's saved data onto the client, returning a boolean representing if it was successful",
				function()
					local MockPlayer = MockInstance.new("Player")
					local Client = SoccerDuels.newClient(MockPlayer)

					assert(nil == Client:GetPlayerSaveData())

					local success = Client:LoadPlayerDataAsync() -- because this is in testing mode, it's not actually async here
					local PlayerSaveData = Client:GetPlayerSaveData()

					assert(typeof(success) == "boolean")
					assert(typeof(PlayerSaveData) == "table")

					-- should load default data for our player
					local DefaultPlayerSaveData = SoccerDuels.getConstant("DefaultPlayerSaveData")

					assert(Utility.tableDeepEqual(DefaultPlayerSaveData, PlayerSaveData))
				end
			)
			it("Triggers an event when the player data has successfully loaded", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				-- no callback upon connect if player data isn't loaded yet
				local changeCount = 0
				local PlayerSaveData
				local callback = function(SaveData)
					changeCount += 1
					PlayerSaveData = SaveData
				end
				local conn = Client:OnPlayerSaveDataLoadedConnect(callback)

				assert(changeCount == 0)
				assert(PlayerSaveData == nil)

				Client:LoadPlayerDataAsync() -- not actually async in testing mode

				assert(changeCount == 1)
				assert(Utility.tableDeepEqual(PlayerSaveData, Client:GetPlayerSaveData()))

				Client:LoadPlayerDataAsync()

				assert(changeCount == 2)
				assert(Utility.tableDeepEqual(PlayerSaveData, Client:GetPlayerSaveData()))

				conn:Disconnect()
				Client:LoadPlayerDataAsync()

				PlayerSaveData = nil

				assert(changeCount == 2)
				assert(PlayerSaveData == nil)

				-- invoke callback upon connect if player data is loaded
				local MockPlayer1 = MockInstance.new("Player")
				local Client1 = SoccerDuels.newClient(MockPlayer1)
				Client1:LoadPlayerDataAsync()

				changeCount = 0
				PlayerSaveData = nil
				conn = Client1:OnPlayerSaveDataLoadedConnect(callback)

				assert(changeCount == 1)
				assert(Utility.tableDeepEqual(PlayerSaveData, Client1:GetPlayerSaveData()))

				conn:Disconnect()
			end)
			it(
				"Clones UserInterface ScreenGuis into the Player's PlayerGui once PlayerSaveData has been loaded",
				function()
					local MockPlayer = MockInstance.new("Player")
					local PlayerGuiFolder = MockPlayer.PlayerGui
					local Client = SoccerDuels.newClient(MockPlayer)

					assert(#PlayerGuiFolder:GetChildren() == 0)

					Client:LoadPlayerDataAsync() -- not actually async when we're in testing mode

					local MainGui = SoccerDuels.getExpectedAsset("MainGui", "PlayerGui", PlayerGuiFolder)

					assert(MainGui)
				end
			)
			it("If there is a LoadingScreen in the PlayerGui, it gets destroyed after PlayerSaveData loads", function()
				local MockPlayer = MockInstance.new("Player")
				local PlayerGuiFolder = MockPlayer.PlayerGui
				local Client = SoccerDuels.newClient(MockPlayer)

				local FakeLoadingScreen = Instance.new("ScreenGui")
				FakeLoadingScreen.Name = "LoadingScreen"
				FakeLoadingScreen.Parent = PlayerGuiFolder

				assert(FakeLoadingScreen.Parent == PlayerGuiFolder)

				Client:LoadPlayerDataAsync() -- not actually async when we're in testing mode

				assert(FakeLoadingScreen.Parent == nil)
			end)
			it("Player's character loads after PlayerSaveData loads, and they can respawn", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				local charAddedCount = 0
				local LastCharacter
				MockPlayer.CharacterAdded:Connect(function(Char)
					charAddedCount += 1
					LastCharacter = Char
				end)

				assert(charAddedCount == 0)
				assert(LastCharacter == nil)
				assert(MockPlayer.Character == nil)

				Client:LoadPlayerDataAsync() -- not actually async when we're in testing mode

				assert(charAddedCount == 1)
				assert(LastCharacter == MockPlayer.Character)

				local PrevCharacter = MockPlayer.Character
				local Humanoid = MockPlayer.Character.Humanoid
				Humanoid:TakeDamage(Humanoid.MaxHealth)

				assert(charAddedCount == 2) -- test for respawning
				assert(LastCharacter == MockPlayer.Character)
				assert(PrevCharacter ~= LastCharacter)
			end)
		end)
		describe("SoccerDuels.newPlayerDocument()", function()
			it(
				"Creates a JSON-compatible table for a player's save data, matching Config.DefaultPlayerSaveData",
				function()
					local DefaultPlayerSaveData = SoccerDuels.getConstant("DefaultPlayerSaveData")
					local SaveData = SoccerDuels.newPlayerDocument()

					assert(typeof(SaveData) == "table")
					assert(Utility.tableDeepEqual(SaveData, DefaultPlayerSaveData))
				end
			)
			it("Accepts a table of loaded player save data and updates the values as necessary", function()
				local currentDataFormatVersion = SoccerDuels.getConstant("DefaultPlayerSaveData", "DataFormatVersion")
				local notDefaultLowGraphicsSetting =
					not SoccerDuels.getConstant("DefaultClientSettings", "Low Graphics")
				local LoadedSaveData = {
					DataFormatVersion = -1,
					Level = 1337,
					WinStreak = 2,
					Settings = {
						["Low Graphics"] = notDefaultLowGraphicsSetting,
					},
				}
				local PlayerDocument = SoccerDuels.newPlayerDocument(LoadedSaveData)

				assert(PlayerDocument.Level == 1337)
				assert(PlayerDocument.WinStreak == 2)
				assert(PlayerDocument.Settings["Low Graphics"] == notDefaultLowGraphicsSetting)
				assert(PlayerDocument.DataFormatVersion == currentDataFormatVersion)
			end)
		end)
		describe("SoccerDuels.savePlayerDataAsync()", function()
			it("Saves a a Player's PlayerDocument (save data) to the game's database", function()
				SoccerDuels.resetTestingVariables()
				SoccerDuels.setTestingVariable("TimeTravel", true)
				SoccerDuels.setTestingVariable("SimulateDataStoreBudget", true)
				SoccerDuels.setTestingVariable("DataStoreRequestBudget/Load", 3)
				SoccerDuels.setTestingVariable("DataStoreRequestBudget/Save", 2)

				local DefaultPlayerSaveData = SoccerDuels.getConstant("DefaultPlayerSaveData")
				local notDefaultLowGraphicsSetting =
					not SoccerDuels.getConstant("DefaultClientSettings", "Low Graphics")

				-- getAvailableDataStoreRequests tells us how many Save/Load requests we can make until it refreshes in the next minute
				local MockPlayer = MockInstance.new("Player")
				local s = pcall(SoccerDuels.getAvailableDataStoreRequests, "This isn't a valid request type")

				assert(not s)
				if not (3 == SoccerDuels.getAvailableDataStoreRequests("Load")) then
					error(`{3} != {SoccerDuels.getAvailableDataStoreRequests("Load")}`)
				end
				assert(2 == SoccerDuels.getAvailableDataStoreRequests("Save"))

				-- getPlayerSaveDataAsync should throw if given bad args or the network fails
				s = pcall(SoccerDuels.getPlayerSaveDataAsync, "This isn't a Player")

				assert(not s)
				assert(3 == SoccerDuels.getAvailableDataStoreRequests("Load"))

				SoccerDuels.setTestingVariable("NetworkAutoFail", true)
				s = pcall(SoccerDuels.getPlayerSaveDataAsync, MockPlayer)

				assert(not s)
				assert(3 == SoccerDuels.getAvailableDataStoreRequests("Load"))

				-- getPlayerSaveDataAsync should return a fresh PlayerSaveDataDocument for new players
				SoccerDuels.setTestingVariable("NetworkAutoFail", false)
				local PlayerSaveDataDocument = SoccerDuels.getPlayerSaveDataAsync(MockPlayer)

				assert(Utility.tableDeepEqual(PlayerSaveDataDocument, DefaultPlayerSaveData))
				assert(2 == SoccerDuels.getAvailableDataStoreRequests("Load"))

				PlayerSaveDataDocument.Level = 2
				PlayerSaveDataDocument.WinStreak = 3
				PlayerSaveDataDocument.Settings["Low Graphics"] = notDefaultLowGraphicsSetting

				-- savePlayerDataAsync should throw with bad args or if the network fails
				s = pcall(SoccerDuels.savePlayerDataAsync, "This isn't a Player!")

				assert(not s)
				assert(2 == SoccerDuels.getAvailableDataStoreRequests("Save"))

				s = pcall(SoccerDuels.savePlayerDataAsync, MockPlayer, "This isn't a PlayerDocument!")

				assert(not s)
				assert(2 == SoccerDuels.getAvailableDataStoreRequests("Save"))

				s = pcall(
					SoccerDuels.savePlayerDataAsync,
					MockPlayer,
					{ Level = 2, WinStreak = "This isn't a real PlayerDocument", DataFormatVersion = 0, Settings = {} }
				)

				assert(not s)
				assert(2 == SoccerDuels.getAvailableDataStoreRequests("Save"))

				-- savePlayerDataAsync should actually update the data in the database
				SoccerDuels.savePlayerDataAsync(MockPlayer, PlayerSaveDataDocument)
				local DifferentPlayerDocument = SoccerDuels.getPlayerSaveDataAsync(MockPlayer)

				assert(DifferentPlayerDocument ~= PlayerSaveDataDocument)
				assert(Utility.tableDeepEqual(DifferentPlayerDocument, PlayerSaveDataDocument))
				assert(1 == SoccerDuels.getAvailableDataStoreRequests("Save"))
				assert(1 == SoccerDuels.getAvailableDataStoreRequests("Load"))

				-- getPlayerDataAsync should yield if we hit the "Load" request limit
				local begin
				local deltaTime
				local maxError = 0.0001
				local delayTime

				begin = os.clock()
				SoccerDuels.getPlayerSaveDataAsync(MockPlayer)
				deltaTime = os.clock() - begin

				assert(math.abs(deltaTime) < maxError)
				assert(0 == SoccerDuels.getAvailableDataStoreRequests("Load")) -- (dependent on Config.TestingModeDataStoreRequestLimits)

				delayTime = 0.03
				maxError = 0.003

				task.delay(delayTime, SoccerDuels.setTestingVariable, "DataStoreRequestBudget/Load", 2)

				begin = os.clock()
				SoccerDuels.getPlayerSaveDataAsync(MockPlayer)
				deltaTime = os.clock() - begin

				assert(deltaTime > delayTime - maxError)
				assert(1 == SoccerDuels.getAvailableDataStoreRequests("Load"))

				-- savePlayerDataAsync should yield if we hit the "Save" request limit
				begin = os.clock()
				SoccerDuels.savePlayerDataAsync(MockPlayer, PlayerSaveDataDocument)
				deltaTime = os.clock() - begin

				assert(math.abs(deltaTime) < maxError)
				assert(0 == SoccerDuels.getAvailableDataStoreRequests("Save")) -- (dependent on Config.TestingModeDataStoreRequestLimits)

				delayTime = 0.03
				maxError = 0.003

				task.delay(delayTime, SoccerDuels.setTestingVariable, "DataStoreRequestBudget/Save", 2)

				begin = os.clock()
				SoccerDuels.savePlayerDataAsync(MockPlayer, PlayerSaveDataDocument)
				deltaTime = os.clock() - begin

				assert(deltaTime > delayTime - maxError)
				assert(1 == SoccerDuels.getAvailableDataStoreRequests("Save"))

				SoccerDuels.resetTestingVariables()

				-- TODO lowkey this test needs to be broken up...
				-- TODO put playerdocument on the client?
				-- TODO make the toast notification work with all this
			end)
		end)
		describe("SoccerDuels.saveAllPlayerData()", function()
			it(
				"Polls for players whose data hasn't been synced with the database and saves their data in separate threads",
				function()
					SoccerDuels.resetTestingVariables()
					SoccerDuels.disconnectAllPlayers()
					SoccerDuels.setTestingVariable("DisableAutoSave", true)

					local notDefaultLowGraphicsSetting =
						not SoccerDuels.getConstant("DefaultClientSettings", "Low Graphics")

					local MockPlayer1 = MockInstance.new("Player")
					local MockPlayer2 = MockInstance.new("Player")

					MockPlayer1.UserId = 24823489234 -- these should be unique from any other MockPlayer in the tests
					MockPlayer2.UserId = 12384543503

					local Client1 = SoccerDuels.newClient(MockPlayer1)
					local Client2 = SoccerDuels.newClient(MockPlayer2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()

					assert(SoccerDuels.playerDataIsSaved(MockPlayer1))
					assert(SoccerDuels.playerDataIsSaved(MockPlayer2))

					local newLevel = 1337
					SoccerDuels.updateCachedPlayerSaveData(MockPlayer1, { -- option #1 for changing player data
						Level = newLevel,
						Settings = {
							["Low Graphics"] = notDefaultLowGraphicsSetting,
						},
					})
					local PlayerDocument2 = SoccerDuels.getCachedPlayerSaveData(MockPlayer2)
					PlayerDocument2.Level = newLevel -- option #2 for changing player data
					PlayerDocument2.Settings["Low Graphics"] = notDefaultLowGraphicsSetting

					local NewPlayerDocument = SoccerDuels.newPlayerDocument({
						Level = newLevel,
						Settings = {
							["Low Graphics"] = notDefaultLowGraphicsSetting,
						}
					})

					assert(not SoccerDuels.playerDataIsSaved(MockPlayer1))
					assert(not SoccerDuels.playerDataIsSaved(MockPlayer2))
					assert(Utility.tableDeepEqual(
						NewPlayerDocument,
						SoccerDuels.getCachedPlayerSaveData(MockPlayer1) -- the cache has updated...
					))
					assert(not Utility.tableDeepEqual(
						NewPlayerDocument,
						SoccerDuels.getPlayerSaveDataAsync(MockPlayer1) -- ...but the database has not (yet)
					))
					assert(Utility.tableDeepEqual(
						NewPlayerDocument,
						SoccerDuels.getCachedPlayerSaveData(MockPlayer2) -- the cache has updated...
					))
					assert(not Utility.tableDeepEqual(
						NewPlayerDocument,
						SoccerDuels.getPlayerSaveDataAsync(MockPlayer2) -- ...but the database has not (yet)
					))

					SoccerDuels.saveAllPlayerData()

					assert(SoccerDuels.playerDataIsSaved(MockPlayer1))
					assert(SoccerDuels.playerDataIsSaved(MockPlayer2))
					assert(
						Utility.tableDeepEqual(
							NewPlayerDocument,
							SoccerDuels.getPlayerSaveDataAsync(MockPlayer1)
						)
					)
					assert(
						Utility.tableDeepEqual(
							NewPlayerDocument,
							SoccerDuels.getPlayerSaveDataAsync(MockPlayer2)
						)
					)

					SoccerDuels.resetTestingVariables()
				end
			)
		end)
	end)
end
