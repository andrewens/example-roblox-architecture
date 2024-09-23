-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsStateFolder = script:FindFirstAncestor("State")

local Enums = require(SoccerDuelsModule.Enums)
local ClientModalState = require(SoccerDuelsStateFolder.ClientModalState)

-- const
local MATCH_JOINING_PAD_UI_MODE_ENUM = Enums.getEnum("UserInterfaceMode", "MatchJoiningPad")

-- public / Client class methods
local function getClientUserInterfaceMode(self)
	return Enums.enumToName("UserInterfaceMode", self._UserInterfaceModeEnum)
end
local function setClientUserInterfaceMode(self, userInterfaceMode)
	if not (typeof(userInterfaceMode) == "string") then
		error(`{userInterfaceMode} is not a string!`)
	end

	local uiModeEnum = Enums.getEnum("UserInterfaceMode", userInterfaceMode)
	if uiModeEnum == nil then
		error(`"{userInterfaceMode}" is not a UserInterfaceMode!`)
	end

	if uiModeEnum == self._UserInterfaceModeEnum then
		return
	end

	if uiModeEnum == MATCH_JOINING_PAD_UI_MODE_ENUM then
		ClientModalState.setClientVisibleModal(self, nil)
	end

	self._UserInterfaceModeEnum = uiModeEnum

	for callback, _ in self._UserInterfaceModeChangedCallbacks do
		callback(userInterfaceMode)
	end
end
local function onClientUserInterfaceModeChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._UserInterfaceModeChangedCallbacks[callback] = true

	callback(getClientUserInterfaceMode(self))

	return {
		Disconnect = function()
			self._UserInterfaceModeChangedCallbacks[callback] = nil
		end,
	}
end

return {
	onClientUserInterfaceModeChangedConnect = onClientUserInterfaceModeChangedConnect,
	getClientUserInterfaceMode = getClientUserInterfaceMode,
	setClientUserInterfaceMode = setClientUserInterfaceMode,
}
