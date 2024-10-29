-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("SoccerDuels database", function()
		describe("Client:LoadPlayerDataAsync()", function()
			it(
				"Loads the user's saved data onto the client, returning a boolean representing if it was successful",
				function()
					SoccerDuels.resetTestingVariables()

					local MockPlayer = MockInstance.new("Player")
					MockPlayer.Name = "Joe"
					MockPlayer.UserId = 23984235234

					local defaultLowGraphicsSetting = SoccerDuels.getConstant("DefaultClientSettings", "Low Graphics")
					local PreviousSaveData = SoccerDuels.newPlayerDocument({
						Level = 4,
						WinStreak = 5,
						Settings = {
							["Low Graphics"] = not defaultLowGraphicsSetting,
							["Sound Effects"] = not defaultLowGraphicsSetting,
						},
					})
					SoccerDuels.savePlayerDataAsync(MockPlayer, PreviousSaveData) -- because this is in testing mode, it's not actually async here

					local Client = SoccerDuels.newClient(MockPlayer)

					assert(nil == Client:GetPlayerSaveData())

					local success = Client:LoadPlayerDataAsync() -- because this is in testing mode, it's not actually async here
					local PlayerSaveData = Client:GetPlayerSaveData()

					assert(success == true)
					assert(Utility.tableDeepEqual(PlayerSaveData, PreviousSaveData))

					Client:Destroy()
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
				Client:Destroy()
				Client1:Destroy()
			end)
			it("Clones UserInterface ScreenGuis into the Player's PlayerGui when the client is created", function()
				local MockPlayer = MockInstance.new("Player")
				local PlayerGuiFolder = MockPlayer.PlayerGui
				local Client = SoccerDuels.newClient(MockPlayer)

				assert(#PlayerGuiFolder:GetChildren() == 0)

				Client:LoadPlayerDataAsync() -- not actually async when we're in testing mode

				local MainGui = SoccerDuels.getExpectedAsset("MainGui", "PlayerGui", PlayerGuiFolder)

				assert(MainGui) -- this is technically redundant because getExpectedAsset() asserts the asset exists

				Client:Destroy()
			end)
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

				Client:Destroy()
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

				if not (charAddedCount == 2) then-- test for respawning
					error(`{charAddedCount} != 2`)
				end
				assert(LastCharacter == MockPlayer.Character)
				assert(PrevCharacter ~= LastCharacter)

				Client:Destroy()
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
				local maxError = 0.001
				local delayTime

				begin = os.clock()
				SoccerDuels.getPlayerSaveDataAsync(MockPlayer)
				deltaTime = os.clock() - begin

				if not (math.abs(deltaTime) < maxError) then
					error(`{deltaTime} != 0`)
				end
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
						},
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
					assert(Utility.tableDeepEqual(NewPlayerDocument, SoccerDuels.getPlayerSaveDataAsync(MockPlayer1)))
					assert(Utility.tableDeepEqual(NewPlayerDocument, SoccerDuels.getPlayerSaveDataAsync(MockPlayer2)))

					SoccerDuels.resetTestingVariables()
					Client1:Destroy()
					Client2:Destroy()
				end
			)
		end)
		describe("Player save data", function()
			it("Initial values", function()
				SoccerDuels.resetTestingVariables()

				local Player = MockInstance.new("Player")
				Player.UserId = 1239804234

				local Client = SoccerDuels.newClient(Player)
				Client:LoadPlayerDataAsync()

				-- verify initial save data is correct
				local SaveData = SoccerDuels.getCachedPlayerSaveData(Player)
				local DataValues = {
					Level = 0,
					ExperiencePoints = 0,

					Wins = 0,
					Losses = 0,
					WinStreak = 0,

					Goals = 0,
					Assists = 0,
					Tackles = 0,
				}

				local i = 0
				for valueName, value in DataValues do
					if not (SaveData[valueName] == value) then
						error(`SaveData["{valueName}"] is {SaveData[valueName]} which is not {value}!`)
					end

					i += 1
					DataValues[valueName] += i
				end

				-- values should all be 'saveable'
				SoccerDuels.updateCachedPlayerSaveData(Player, DataValues)
				SoccerDuels.saveAllPlayerData()
				SaveData = SoccerDuels.getPlayerSaveDataAsync(Player)

				for valueName, value in DataValues do
					if not (SaveData[valueName] == value) then
						error(`SaveData["{valueName}"]: {SaveData[valueName]} != {value}`)
					end
				end

				-- values should update on the client
				for valueName, value in DataValues do
					if not (Client:GetAnyPlayerDataValue(valueName, Player) == value) then
						error(`"{valueName}": {Client:GetAnyPlayerDataValue(valueName, Player)} != {value}`)
					end
				end

				-- cleanup
				Client:Destroy()
			end)
			it("Player win rate is just the ratio of wins to total games played", function()
				SoccerDuels.resetTestingVariables()

				local Player = MockInstance.new("Player")
				Player.UserId = 349805341

				local Client = SoccerDuels.newClient(Player)
				Client:LoadPlayerDataAsync()

				-- initial values
				local SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 0)
				assert(SaveData.Losses == 0)
				assert(SaveData.WinRate == 0)

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 0)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 0)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 0)

				-- if losses are 0, and wins are > 0, the winRate is 1
				SoccerDuels.updateCachedPlayerSaveData(Player, {
					Wins = 1,
				})
				SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 1)
				assert(SaveData.Losses == 0)
				assert(SaveData.WinRate == 1)

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 1)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 0)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 1)

				SoccerDuels.updateCachedPlayerSaveData(Player, {
					Wins = 2349,
				})
				SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 2349)
				assert(SaveData.Losses == 0)
				assert(SaveData.WinRate == 1)

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 2349)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 0)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 1)

				-- otherwise WinRate is the ratio of wins to total games played
				SoccerDuels.updateCachedPlayerSaveData(Player, {
					Wins = 0,
					Losses = 5,
				})
				SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 0)
				assert(SaveData.Losses == 5)
				assert(SaveData.WinRate == 0)

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 0)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 5)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 0)

				SoccerDuels.updateCachedPlayerSaveData(Player, {
					Wins = 3,
					Losses = 2,
				})
				SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 3)
				assert(SaveData.Losses == 2)
				assert(SaveData.WinRate == 3 / 5)

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 3)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 2)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 3 / 5)

				SoccerDuels.updateCachedPlayerSaveData(Player, {
					Wins = 99,
					Losses = 999,
				})
				SaveData = SoccerDuels.getCachedPlayerSaveData(Player)

				assert(SaveData.Wins == 99)
				assert(SaveData.Losses == 999)
				assert(SaveData.WinRate == 99 / (99 + 999))

				assert(Client:GetAnyPlayerDataValue("Wins", Player) == 99)
				assert(Client:GetAnyPlayerDataValue("Losses", Player) == 999)
				assert(Client:GetAnyPlayerDataValue("WinRate", Player) == 99 / (99 + 999))

				-- cleanup
				Client:Destroy()
			end)
		end)
	end)
end
