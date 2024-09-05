--[[
    There is a duplicate Event module in SoccerDuels.
    I am preventing SoccerDuels from having external dependencies.

    September 5, 2024
    Andrew Ens
]]

-- var
local EventMetatable

-- public / Event class methods
local function eventConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._Callbacks[callback] = true

	return {
		Disconnect = function()
			self._Callbacks[callback] = nil
		end,
	}
end
local function eventFire(self, ...)
	for callback, _ in self._Callbacks do
		callback(...)
	end
end

-- public
local function newEvent()
	local self = {}
	self._Callbacks = {} -- function callback(...) --> true

	setmetatable(self, EventMetatable)

	return self
end
local function initializeEvent()
	local EventMethods = {
		Connect = eventConnect,
		Fire = eventFire,
	}
	EventMetatable = { __index = EventMethods }
end

initializeEvent()

return {
	new = newEvent,
	-- initialize = initializeEvent,
}
