-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("SoccerDuels.newClient()", function()
		it("Creates a new Client object, provided a Player Instance or mock Player", function()
			local MockPlayer = MockInstance.new("Player")
			local Client = SoccerDuels.newClient(MockPlayer)

			assert(typeof(Client) == "table")

			local s = pcall(SoccerDuels.newClient, nil)

			assert(not s)

			s = pcall(SoccerDuels.newClient, Instance.new("Part"))

			assert(not s)

			Client:Destroy()
		end)
		it("Client fires an event when other loaded clients' characters load", function()
			SoccerDuels.disconnectAllPlayers()

			local MockPlayer1 = MockInstance.new("Player")
			local MockPlayer2 = MockInstance.new("Player")

			MockPlayer1.Name = "Fred"
			MockPlayer2.Name = "Frank"

			local Client1 = SoccerDuels.newClient(MockPlayer1)
			local Client2 = SoccerDuels.newClient(MockPlayer2)

			local charAddedCount = 0
			local LastPlayerSpawned, LastCharacter
			local callback = function(Character, Player)
				charAddedCount += 1
				LastPlayerSpawned = Player
				LastCharacter = Character
			end

			local conn = Client1:OnCharacterSpawnedInLobbyConnect(callback)

			-- characters spawn when their data loads and when they die/reset
			assert(charAddedCount == 0)

			Client1:LoadPlayerDataAsync()

			assert(MockPlayer1.Character)
			if not (charAddedCount == 1) then
				error(`{charAddedCount} != 1`)
			end
			assert(LastPlayerSpawned == MockPlayer1)
			assert(LastCharacter == MockPlayer1.Character)

			MockPlayer1.Character.Humanoid:TakeDamage(math.huge)

			assert(charAddedCount == 2)
			assert(LastPlayerSpawned == MockPlayer1)
			assert(LastCharacter == MockPlayer1.Character)

			Client2:LoadPlayerDataAsync()

			assert(MockPlayer2.Character)
			if not (charAddedCount == 3) then
				error(`{charAddedCount} != 3`)
			end
			assert(LastPlayerSpawned == MockPlayer2)
			assert(LastCharacter == MockPlayer2.Character)

			MockPlayer2.Character.Humanoid:TakeDamage(math.huge)

			assert(charAddedCount == 4)
			assert(LastPlayerSpawned == MockPlayer2)
			assert(LastCharacter == MockPlayer2.Character)

			conn:Disconnect()
			MockPlayer1.Character.Humanoid:TakeDamage(math.huge)

			assert(charAddedCount == 4)
			assert(LastPlayerSpawned == MockPlayer2)
			assert(LastCharacter == MockPlayer2.Character)

			-- there will be three characters loaded right now (after client #3 loads), and the callback should fire for all of them
			charAddedCount = 0
			LastPlayerSpawned, LastCharacter = nil, nil

			local MockPlayer3 = MockInstance.new("Player")
			local Client3 = SoccerDuels.newClient(MockPlayer3)

			conn = Client3:OnCharacterSpawnedInLobbyConnect(callback)
			Client3:LoadPlayerDataAsync()

			assert(charAddedCount == 3)
			assert(
				LastPlayerSpawned == MockPlayer1 or LastPlayerSpawned == MockPlayer2 or LastPlayerSpawned == MockPlayer3
			)
			assert(
				LastCharacter == MockPlayer1.Character
					or LastCharacter == MockPlayer2.Character
					or LastCharacter == MockPlayer3.Character
			)

			-- if a client disconnects, their character shouldn't be loaded anymore
			conn:Disconnect()
			SoccerDuels.disconnectPlayer(MockPlayer1)

			charAddedCount = 0
			LastPlayerSpawned, LastCharacter = nil, nil
			conn = Client3:OnCharacterSpawnedInLobbyConnect(callback)

			assert(charAddedCount == 2)
			assert(LastPlayerSpawned == MockPlayer2 or LastPlayerSpawned == MockPlayer3)
			assert(LastCharacter == MockPlayer2.Character or LastCharacter == MockPlayer3.Character)

			-- end test
			conn:Disconnect()
			SoccerDuels.disconnectAllPlayers()

			-- TODO later test that this does NOT fire when a player spawns a character into a match
			SoccerDuels.resetTestingVariables()
			Client1:Destroy()
			Client2:Destroy()
			Client3:Destroy()
		end)
		it("Clients maintain a cache of all other clients' PlayerDocuments", function()
			SoccerDuels.disconnectAllPlayers()

			local MockPlayer1 = MockInstance.new("Player")
			local MockPlayer2 = MockInstance.new("Player")

			MockPlayer1.UserId = 234823623234
			MockPlayer2.UserId = 230842834823

			MockPlayer1.Name = "Louise"
			MockPlayer2.Name = "Gertrude"

			local Client1 = SoccerDuels.newClient(MockPlayer1)
			local Client2 = SoccerDuels.newClient(MockPlayer2)

			Client1:LoadPlayerDataAsync()
			Client2:LoadPlayerDataAsync()

			assert(Client1:GetAnyPlayerDataValue("Level", MockPlayer1) == 0)
			assert(Client2:GetAnyPlayerDataValue("Level", MockPlayer1) == 0)
			assert(Client1:GetAnyPlayerDataValue("Level", MockPlayer2) == 0)
			assert(Client2:GetAnyPlayerDataValue("Level", MockPlayer2) == 0)

			SoccerDuels.updateCachedPlayerSaveData(MockPlayer1, {
				Level = 2,
			})

			assert(Client1:GetAnyPlayerDataValue("Level", MockPlayer1) == 2)
			assert(Client2:GetAnyPlayerDataValue("Level", MockPlayer1) == 2)
			assert(Client1:GetAnyPlayerDataValue("Level", MockPlayer2) == 0)
			assert(Client2:GetAnyPlayerDataValue("Level", MockPlayer2) == 0)

			SoccerDuels.updateCachedPlayerSaveData(MockPlayer1, {
				WinStreak = 3,
			})

			assert(Client1:GetAnyPlayerDataValue("WinStreak", MockPlayer1) == 3)
			assert(Client2:GetAnyPlayerDataValue("WinStreak", MockPlayer1) == 3)
			assert(Client1:GetAnyPlayerDataValue("WinStreak", MockPlayer2) == 0)
			assert(Client2:GetAnyPlayerDataValue("WinStreak", MockPlayer2) == 0)

			local s1 = pcall(Client1.GetAnyPlayerDataValue, Client1, "This isn't a value", MockPlayer1)
			local s2 = pcall(Client2.GetAnyPlayerDataValue, Client2, "WinStreak", "This isn't a player")

			assert(not s1)
			assert(not s2)

			Client1:Destroy()
			Client2:Destroy()
		end)
	end)
	describe("SoccerDuels testing API", function()
		describe("SoccerDuels.wait()", function()
			it("Exposes a wait method that doesn't wait if we're in TimeTravel testing mode", function()
				SoccerDuels.setTestingVariable("TimeTravel", false)

				local begin
				local deltaTime
				local maxError = 0.0001

				begin = os.clock()
				SoccerDuels.wait()
				deltaTime = os.clock() - begin

				if not (deltaTime > 0.008) then
					error(`{deltaTime} <= 0.008`)
				end

				SoccerDuels.setTestingVariable("TimeTravel", true)

				begin = os.clock()
				SoccerDuels.wait()
				deltaTime = os.clock() - begin

				if not (math.abs(deltaTime) < maxError) then
					error(`{deltaTime} != 0`)
				end

				SoccerDuels.resetTestingVariables()
			end)
		end)
	end)
	describe("SoccerDuels.getLoadedPlayers()", function()
		it("Returns a list of players whose clients have loaded", function()
			SoccerDuels.disconnectAllPlayers()

			local MockPlayer1 = MockInstance.new("Player")
			local MockPlayer2 = MockInstance.new("Player")
			MockPlayer1.Name = "Billy"
			MockPlayer2.Name = "Bob"

			local Client1 = SoccerDuels.newClient(MockPlayer1)

			assert(typeof(SoccerDuels.getLoadedPlayers()) == "table")
			if not (#SoccerDuels.getLoadedPlayers() == 0) then
				error(`{#SoccerDuels.getLoadedPlayers()} != 0`)
			end

			Client1:LoadPlayerDataAsync()

			if not (#SoccerDuels.getLoadedPlayers() == 1) then
				error(`{#SoccerDuels.getLoadedPlayers()} != 1`)
			end
			assert(SoccerDuels.getLoadedPlayers()[1] == MockPlayer1)

			local Client2 = SoccerDuels.newClient(MockPlayer2)
			Client2:LoadPlayerDataAsync()

			assert(#SoccerDuels.getLoadedPlayers() == 2)
			assert(Utility.tableContainsValue(SoccerDuels.getLoadedPlayers(), MockPlayer1))
			assert(Utility.tableContainsValue(SoccerDuels.getLoadedPlayers(), MockPlayer2))

			SoccerDuels.disconnectPlayer(MockPlayer2)

			assert(#SoccerDuels.getLoadedPlayers() == 1)
			assert(SoccerDuels.getLoadedPlayers()[1] == MockPlayer1)

			SoccerDuels.disconnectPlayer(MockPlayer1)

			assert(#SoccerDuels.getLoadedPlayers() == 0)

			Client1:Destroy()
			Client2:Destroy()
		end)
	end)
end
