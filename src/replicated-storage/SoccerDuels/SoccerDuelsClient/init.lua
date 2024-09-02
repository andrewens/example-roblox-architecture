-- dependency
local SoccerDuelsModule = script.Parent

local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)

-- var
local ClientMetatable

-- public / Client class methods
local function getClientVisibleModalName(self)
	return Enums.enumToName("ModalEnum", self._VisibleModalEnum)
end
local function toggleClientModalVisibility(self, modalName)
	local modalEnum = Enums.getEnum("ModalEnum", modalName)
	if modalEnum == nil then
		error(`There's no Modal named "{modalName}"`)
	end

	self._VisibleModalEnum = if self._VisibleModalEnum == modalEnum then nil else modalEnum
end

-- public
local function newClient(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player Instance!`)
	end

	local self = {}

	-- private properties (don't use outside of this module)
	self._Player = Player
	self._VisibleModalEnum = nil -- int | nil

	setmetatable(self, ClientMetatable)

	return self
end
local function initializeClients()
	local ClientMethods = {
		GetVisibleModalName = getClientVisibleModalName,
		ToggleModalVisibility = toggleClientModalVisibility,
	}
	ClientMetatable = { __index = ClientMethods }
end

return {
	new = newClient,
	initialize = initializeClients,
}
