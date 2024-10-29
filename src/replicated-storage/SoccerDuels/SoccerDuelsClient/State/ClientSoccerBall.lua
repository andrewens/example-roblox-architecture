-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Network = require(SoccerDuelsModule.Network)

-- public / Client class methods
local function clientKickSoccerBall(self, direction, speed)
    if not (typeof(direction) == "Vector3") then
        error(`{direction} is not a Vector3!`)
    end
    if not (typeof(speed) == "number") then
        error(`{speed} is not a number!`)
    end

	Network.fireServer("PlayerKickSoccerBall", self.Player, direction, speed)
end

return {
	clientKickSoccerBall = clientKickSoccerBall,
}
