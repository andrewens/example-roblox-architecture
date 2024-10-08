-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	it("Clients can read the name of the map they get connected to + their team index", function()
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

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		SoccerDuels.connectPlayerToMapInstance(Player1, mapId, 2)

		assert(Client1:GetConnectedMapName() == "Stadium")
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == 2)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == 2)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		SoccerDuels.connectPlayerToMapInstance(Player2, mapId, 1)

		assert(Client1:GetConnectedMapName() == "Stadium")
		assert(Client2:GetConnectedMapName() == "Stadium")
		assert(Client1:GetPlayerTeamIndex(Player1) == 2)
		assert(Client1:GetPlayerTeamIndex(Player2) == 1)
		assert(Client2:GetPlayerTeamIndex(Player1) == 2)
		assert(Client2:GetPlayerTeamIndex(Player2) == 1)

		SoccerDuels.disconnectPlayerFromAllMapInstances(Player1)

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == "Stadium")
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == 1)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == 1)

		SoccerDuels.destroyMapInstance(mapId)

		assert(Client1:GetConnectedMapName() == nil)
		assert(Client2:GetConnectedMapName() == nil)
		assert(Client1:GetPlayerTeamIndex(Player1) == nil)
		assert(Client1:GetPlayerTeamIndex(Player2) == nil)
		assert(Client2:GetPlayerTeamIndex(Player1) == nil)
		assert(Client2:GetPlayerTeamIndex(Player2) == nil)

		Client1:Destroy()
		Client2:Destroy()
	end)
end
