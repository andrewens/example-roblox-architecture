-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	it("The server caches a player's country when they join the game and replicates it to all clients", function()
		SoccerDuels.resetTestingVariables()

		local Player1 = MockInstance.new("Player")
		local Player2 = MockInstance.new("Player")

		Player1.UserId = 9792010 -- this is Rockraider400's user id & the testing system should always assign "US" to it
		Player2.UserId = 394853489

		local Client1 = SoccerDuels.newClient(Player1)
		local Client2 = SoccerDuels.newClient(Player2)

		assert(SoccerDuels.getPlayerRegion(Player1) == nil)
		assert(SoccerDuels.getPlayerRegion(Player2) == nil)
		assert(Client1:GetAnyPlayerRegion(Player1) == nil)
		assert(Client1:GetAnyPlayerRegion(Player2) == nil)
		assert(Client2:GetAnyPlayerRegion(Player1) == nil)
		assert(Client2:GetAnyPlayerRegion(Player2) == nil)

		Client1:LoadPlayerDataAsync()

		assert(SoccerDuels.getPlayerRegion(Player1) == "US")
		assert(SoccerDuels.getPlayerRegion(Player2) == nil)
		assert(Client1:GetAnyPlayerRegion(Player1) == "US")
		assert(Client1:GetAnyPlayerRegion(Player2) == nil)
		assert(Client2:GetAnyPlayerRegion(Player1) == nil) -- Client2 hasn't loaded yet
		assert(Client2:GetAnyPlayerRegion(Player2) == nil)

		Client2:LoadPlayerDataAsync()
		local player2Region = SoccerDuels.getPlayerRegion(Player2)

		assert(SoccerDuels.getPlayerRegion(Player1) == "US")
		assert(typeof(player2Region) == "string")
		assert(SoccerDuels.getEnum("CountryRegionCode", player2Region))
		assert(Client1:GetAnyPlayerRegion(Player1) == "US")
		assert(Client1:GetAnyPlayerRegion(Player2) == player2Region)
		assert(Client2:GetAnyPlayerRegion(Player1) == "US")
		assert(Client2:GetAnyPlayerRegion(Player2) == player2Region)

		Client1:Destroy()
		Client2:Destroy()
		SoccerDuels.resetTestingVariables()
	end)
end
