-- dependency
local SoccerDuelsModule = script.Parent

local AssetDependencies = require(SoccerDuelsModule.AssetDependencies)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)

local WindowsScreenGui = AssetDependencies.getExpectedAsset("WindowsGui")

-- var
local ClientMetatable

-- public / Client class methods
local function getClientVisibleModalName(self)
	return Enums.enumToName("ModalEnum", self._VisibleModalEnum)
end
local function clientOnVisibleModalChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	callback(getClientVisibleModalName(self))
	self._VisibleModalChangedCallbacks[callback] = true

	return {
		Disconnect = function()
			self._VisibleModalChangedCallbacks[callback] = nil
		end
	}
end
local function toggleClientModalVisibility(self, modalName)
	local modalEnum = Enums.getEnum("ModalEnum", modalName)
	if modalEnum == nil then
		error(`There's no Modal named "{modalName}"`)
	end

	self._VisibleModalEnum = if self._VisibleModalEnum == modalEnum then nil else modalEnum

	for callback, _ in self._VisibleModalChangedCallbacks do
		callback(getClientVisibleModalName(self))
	end
end
local function destroyClient(self)
	self._VisibleModalChangedCallbacks = {}
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
	self._VisibleModalChangedCallbacks = {} -- function callback(string visibleModalName) --> true

	setmetatable(self, ClientMetatable)

	-- init
	WindowsScreenGui:Clone().Parent = Player.PlayerGui

	return self
end
local function initializeClients()
	local ClientMethods = {
		OnVisibleModalChangedConnect = clientOnVisibleModalChangedConnect,
		GetVisibleModalName = getClientVisibleModalName,
		ToggleModalVisibility = toggleClientModalVisibility,
		Destroy = destroyClient,
	}
	ClientMetatable = { __index = ClientMethods }
end

return {
	new = newClient,
	initialize = initializeClients,
}
