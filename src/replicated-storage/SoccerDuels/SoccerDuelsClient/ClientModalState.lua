-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)

-- public
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
		end,
	}
end
local function setClientVisibleModal(self, modalName) -- TODO this method is untested :^)
	if modalName then
		local modalEnum = Enums.getEnum("ModalEnum", modalName)
		if modalEnum == nil then
			error(`There's no Modal named "{modalName}"`)
		end

		self._VisibleModalEnum = modalEnum
	else
		self._VisibleModalEnum = nil
	end

	for callback, _ in self._VisibleModalChangedCallbacks do
		callback(getClientVisibleModalName(self))
	end
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

return {
    getClientVisibleModalName = getClientVisibleModalName,
    clientOnVisibleModalChangedConnect = clientOnVisibleModalChangedConnect,
    setClientVisibleModal = setClientVisibleModal,
    toggleClientModalVisibility = toggleClientModalVisibility,
}
