-- dependency
local SoccerDuelsModule = script.Parent

local Utility = require(SoccerDuelsModule.Utility)

-- public
local function newClient(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player Instance!`)
	end

	return {}
end

return {
	new = newClient,
}
