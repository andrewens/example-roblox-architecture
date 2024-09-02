-- dependency
local SoccerDuelsModule = script.Parent

local Utility = require(SoccerDuelsModule.Utility)

-- var
local ClientMetatable

-- public / Client class methods
local function getClientVisibleModalName(self)
	return self._VisibleModalName
end
local function toggleClientModalVisibility(self, modalName)
	self._VisibleModalName = if self._VisibleModalName == modalName then nil else modalName
end

-- public
local function newClient(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player Instance!`)
	end

	local self = {}

    -- private properties (don't use outside of this module)
	self._Player = Player
	self._VisibleModalName = nil

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
