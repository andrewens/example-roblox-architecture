--[[
    Data type for holding all of a player's save data
]]

-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local DEFAULT_PLAYER_SAVE_DATA = Config.getConstant("DefaultPlayerSaveData")

-- public
local function newPlayerDocument()
	return Utility.tableDeepCopy(DEFAULT_PLAYER_SAVE_DATA)
end

return {
	new = newPlayerDocument,
}
