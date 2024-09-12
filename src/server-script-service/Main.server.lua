local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = ReplicatedStorage.Tests
local TestEZModule = ReplicatedStorage.TestEZ
local MockInstanceModule = ReplicatedStorage.MockInstance

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(MockInstanceModule)
local TestEZ = require(TestEZModule)

SoccerDuels.initialize()

if SoccerDuels.getConstant("TestingMode") then
	local begin = os.clock()

	MockInstance.initialize()
	TestEZ.TestBootstrap:run({ TestsFolder })

	local TestUtility = require(TestsFolder.Utility)
	TestUtility.serverFinishedTests() -- TODO this is a temporary fix

	warn(`Ran tests in {math.floor((os.clock() - begin) * 1000)} ms`)
else
	MockInstanceModule:Destroy()
	TestEZModule:Destroy()
	TestsFolder:Destroy()
end
