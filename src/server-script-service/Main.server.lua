local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = ReplicatedStorage.Tests

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local TestEZ = require(ReplicatedStorage.TestEZ)

SoccerDuels.initialize()
MockInstance.initialize()
TestEZ.TestBootstrap:run({ TestsFolder })
