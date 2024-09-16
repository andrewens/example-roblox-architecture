-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- public
local function notifyPlayer(Player, notificationMessage)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(notificationMessage) == "string") then
		error(`{notificationMessage} is not a string!`)
	end

	Network.fireClient("NotifyPlayer", Player, notificationMessage)
end

return {
	notifyPlayer = notifyPlayer,
}
