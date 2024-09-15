-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local DEFAULT_CONTROLLER_TYPE = Config.getConstant("DefaultControllerType")
local USER_INPUT_TYPE_TO_CONTROLLER_TYPE = Config.getConstant("UserInputTypeToControllerType")
local DEFAULT_CONTROLLER_TYPE_ENUM = Enums.getEnum("ControllerType", DEFAULT_CONTROLLER_TYPE)

-- public / Client class methods
local function clientTapInput(self, InputObject)
	if not Utility.isA(InputObject, "InputObject") then
		error(`{InputObject} is not an InputObject!`)
	end

	local controllerType = USER_INPUT_TYPE_TO_CONTROLLER_TYPE[InputObject.UserInputType.Name]
	if controllerType == nil then
		return
	end

	local prevControllerTypeEnum = self._ControllerTypeEnum
	self._ControllerTypeEnum = Enums.getEnum("ControllerType", controllerType)

	if prevControllerTypeEnum ~= self._ControllerTypeEnum then
		for callback, _ in self._ControllerTypeChangedCallbacks do
			callback(controllerType)
		end
	end
end

local function getClientControllerType(self)
	if self._ControllerTypeEnum then
		return Enums.enumToName("ControllerType", self._ControllerTypeEnum)
	end

	return DEFAULT_CONTROLLER_TYPE
end
local function onClientControllerTypeChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._ControllerTypeChangedCallbacks[callback] = true

	callback(getClientControllerType(self))

	return {
		Disconnect = function()
			self._ControllerTypeChangedCallbacks[callback] = nil
		end,
	}
end
local function initializeClientInput(self)
	self._ControllerTypeEnum = DEFAULT_CONTROLLER_TYPE_ENUM
end

-- public
local function initializeClientInputModule()
	if DEFAULT_CONTROLLER_TYPE_ENUM == nil then
		error(`Config.DefaultControllerType is set to "{DEFAULT_CONTROLLER_TYPE}", which is not a ControllerType Enum`)
	end
end

return {
	-- Client class methods
	clientTapInput = clientTapInput,

	onClientControllerTypeChangedConnect = onClientControllerTypeChangedConnect,
	getClientControllerType = getClientControllerType,

	initializeClientInput = initializeClientInput,

	-- root
	initialize = initializeClientInputModule,
}
