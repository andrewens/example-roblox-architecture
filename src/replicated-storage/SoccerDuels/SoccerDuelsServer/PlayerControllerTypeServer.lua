-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)

-- const
local DEFAULT_CONTROLLER_TYPE = Config.getConstant("DefaultControllerType")

-- var
local PlayerControllerTypeEnums = {} -- Player --> int controllerTypeEnum

-- private
local function rawsetPlayerControllerType(Player, controllerTypeEnum)
	PlayerControllerTypeEnums[Player] = controllerTypeEnum
	Network.fireAllClients("PlayerControllerTypeChanged", Player, controllerTypeEnum)
end

-- protected / Network methods
local function playerControllerTypeChanged(Player, controllerTypeEnum)
	if PlayerControllerTypeEnums[Player] == nil then
		return -- Player has left the game
	end
	if not Enums.enumToName("ControllerType", controllerTypeEnum) then
		error(`{controllerTypeEnum} is not a controller type enum!`)
	end

	rawsetPlayerControllerType(Player, controllerTypeEnum)
end
local function onPlayerRequestPlayersControllerTypeEnums(RequestingPlayer)
	for OtherPlayer, controllerTypeEnum in PlayerControllerTypeEnums do
		-- ** RequestingPlayer is probably not in PlayerControllerTypeEnums yet
		Network.fireClient("PlayerControllerTypeChanged", RequestingPlayer, OtherPlayer, controllerTypeEnum)
	end

	rawsetPlayerControllerType(RequestingPlayer, Enums.getEnum("ControllerType", DEFAULT_CONTROLLER_TYPE))
end

-- public
local function disconnectPlayer(Player)
	PlayerControllerTypeEnums[Player] = nil
	Network.fireAllClients("PlayerControllerTypeChanged", Player, nil)
end
local function initializePlayerControllerTypeServer()
	Network.onServerEventConnect("PlayerControllerTypeChanged", playerControllerTypeChanged)
	Network.onServerEventConnect("GetPlayersControllerTypeEnums", onPlayerRequestPlayersControllerTypeEnums)
end

return {
	disconnectPlayer = disconnectPlayer,
	initialize = initializePlayerControllerTypeServer,
}
