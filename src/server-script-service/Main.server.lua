local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = ReplicatedStorage.Tests
local TestEZ = require(ReplicatedStorage.TestEZ)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

SoccerDuels.initialize()
TestEZ.TestBootstrap:run({ TestsFolder })
