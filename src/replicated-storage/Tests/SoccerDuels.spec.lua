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
		end)
	end)
end
