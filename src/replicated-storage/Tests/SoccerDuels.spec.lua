local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

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
end
