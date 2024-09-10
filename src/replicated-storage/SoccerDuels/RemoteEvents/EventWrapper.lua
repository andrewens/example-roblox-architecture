-- dependency
local RunService = game:GetService("RunService")

-- const
local IS_SERVER = RunService:IsServer()

-- var
local EventMetatable

-- public / Event class methods
local function eventConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._Callbacks[callback] = true
	local conn = self._RemoteEvent[if IS_SERVER then "OnServerEvent" else "OnClientEvent"]:Connect(callback)

	return {
		Disconnect = function()
			self._Callbacks[callback] = nil
			conn:Disconnect()
		end,
	}
end
local function eventFire(self, ...)
	for callback, _ in self._Callbacks do
		callback(...)
	end
end

-- public
local function newEvent(RemoteEvent)
	local self = {}
	self._Callbacks = {} -- function callback(...) --> true
	self._RemoteEvent = RemoteEvent

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
