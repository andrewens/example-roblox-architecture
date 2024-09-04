local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = ReplicatedStorage.Tests
local TestEZModule = ReplicatedStorage.TestEZ
local MockInstanceModule = ReplicatedStorage.MockInstance

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(MockInstanceModule)
local TestEZ = require(TestEZModule)

SoccerDuels.initialize()

if SoccerDuels.getConstant("TestingMode") then
	MockInstance.initialize()
	TestEZ.TestBootstrap:run({ TestsFolder })
else
	MockInstanceModule:Destroy()
	TestEZModule:Destroy()
	TestsFolder:Destroy()
end
