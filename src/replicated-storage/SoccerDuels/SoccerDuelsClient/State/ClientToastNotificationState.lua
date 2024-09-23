-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Network = require(SoccerDuelsModule.Network)

-- protected / Client network methods
local function onNotifyClient(self, toastMessage)
	for callback, _ in self._ToastCallbacks do
		callback(toastMessage)
	end
end
local function initializeClientToastNotifications(self)
	Network.onClientEventConnect("NotifyPlayer", self.Player, function(...)
		onNotifyClient(self, ...)
	end)
end

-- public / Client class methods
local function onClientToastNotificationConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._ToastCallbacks[callback] = true

	return {
		Disconnect = function()
			self._ToastCallbacks[callback] = nil
		end,
	}
end

return {
	onClientToastNotificationConnect = onClientToastNotificationConnect,
	initializeClientToastNotifications = initializeClientToastNotifications,
}
