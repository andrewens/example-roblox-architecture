local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

local LocalPlayer = Players.LocalPlayer

SoccerDuels.initialize()
SoccerDuels.newClient(LocalPlayer)
