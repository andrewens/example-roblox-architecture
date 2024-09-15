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

	if controllerType == DEFAULT_CONTROLLER_TYPE then
		self._ControllerTypeEnum = nil
		return
	end

	self._ControllerTypeEnum = Enums.getEnum("ControllerType", controllerType)
end
local function getClientControllerType(self)
	if self._ControllerTypeEnum then
		return Enums.enumToName("ControllerType", self._ControllerTypeEnum)
	end

	return DEFAULT_CONTROLLER_TYPE
end

-- public
local function initializeClientInput()
	if DEFAULT_CONTROLLER_TYPE_ENUM == nil then
		error(`Config.DefaultControllerType is set to "{DEFAULT_CONTROLLER_TYPE}", which is not a ControllerType Enum`)
	end
end

return {
	-- Client class methods
	clientTapInput = clientTapInput,
	getClientControllerType = getClientControllerType,

	-- root
	initialize = initializeClientInput,
}
