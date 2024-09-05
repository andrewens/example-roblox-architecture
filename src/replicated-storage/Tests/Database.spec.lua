-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

-- private
local function tableDeepEqual(Table1, Table2)
	if typeof(Table1) == "table" and typeof(Table2) == "table" then
		for k, v in Table1 do
			if not tableDeepEqual(v, Table2[k]) then
				return false, `{v} != {Table2[k]} (key: "{k}")`
			end
		end
		for k, v in Table2 do -- redundant, but avoids extra memory
			if not tableDeepEqual(v, Table1[k]) then
				return false, `{v} != {Table1[k]} (key: "{k}")`
			end
		end

		return true
	end

	if Table1 ~= Table2 then
		return false, `{Table1} != {Table2}`
	end

	return true
end

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

					assert(tableDeepEqual(DefaultPlayerSaveData, PlayerSaveData))
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
				assert(tableDeepEqual(PlayerSaveData, Client:GetPlayerSaveData()))

				Client:LoadPlayerDataAsync()

				assert(changeCount == 2)
				assert(tableDeepEqual(PlayerSaveData, Client:GetPlayerSaveData()))

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
				assert(tableDeepEqual(PlayerSaveData, Client1:GetPlayerSaveData()))

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
	end)
end
