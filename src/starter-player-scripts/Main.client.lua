-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

local LocalPlayer = Players.LocalPlayer

-- initialize
SoccerDuels.initialize()

local begin = os.clock()
local Client = SoccerDuels.newClient(LocalPlayer)
local s = Client:LoadPlayerDataAsync()

if s then
	warn(`Loaded client in {math.floor(1000 * (os.clock() - begin))} ms`)
else
	warn("CLIENT FAILED TO LOAD DATA")
end
