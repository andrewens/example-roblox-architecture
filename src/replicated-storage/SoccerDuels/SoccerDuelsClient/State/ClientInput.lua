-- dependency
local UserInputService = game:GetService("UserInputService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script:FindFirstAncestor("State")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

local ClientMapState = require(SoccerDuelsClientStateFolder.ClientMapState)
local ClientModalState = require(SoccerDuelsClientStateFolder.ClientModalState)

-- const
local DEFAULT_CONTROLLER_TYPE = Config.getConstant("DefaultControllerType")
local USER_INPUT_TYPE_TO_CONTROLLER_TYPE = Config.getConstant("UserInputTypeToControllerType")
local DEFAULT_LEADERBOARD_KEY = Config.getConstant("DefaultKeybinds", "Leaderboard")

local DEFAULT_CONTROLLER_TYPE_ENUM = Enums.getEnum("ControllerType", DEFAULT_CONTROLLER_TYPE)

-- protected / Network methods
local function onPlayerControllerTypeChanged(self, Player, controllerTypeEnum)
	if Player == self.Player then
		return
	end
	if self._ControllerTypeEnum[Player] == controllerTypeEnum then
		return
	end

	self._ControllerTypeEnum[Player] = controllerTypeEnum

	local controllerType = Enums.enumToName("ControllerType", controllerTypeEnum)
	for callback, _ in self._ControllerTypeChangedCallbacks do
		callback(Player, controllerType)
	end
end

-- public / Client class methods
local function clientBeginInput(self, InputObject)
	if not Utility.isA(InputObject, "InputObject") then
		error(`{InputObject} is not an InputObject!`)
	end

	if InputObject.KeyCode == DEFAULT_LEADERBOARD_KEY then
		if ClientMapState.getClientConnectedMapName(self) then
			ClientModalState.setClientVisibleModal(self, "Leaderboard")
		end
	end
end
local function clientEndInput(self, InputObject)
	if not Utility.isA(InputObject, "InputObject") then
		error(`{InputObject} is not an InputObject!`)
	end

	if InputObject.KeyCode == DEFAULT_LEADERBOARD_KEY then
		if ClientModalState.getClientVisibleModalName(self) == "Leaderboard" then
			ClientModalState.setClientVisibleModal(self, nil)
		end
	end
end
local function clientTapInput(self, InputObject)
	if not Utility.isA(InputObject, "InputObject") then
		error(`{InputObject} is not an InputObject!`)
	end

	local controllerType = USER_INPUT_TYPE_TO_CONTROLLER_TYPE[InputObject.UserInputType.Name]
	if controllerType == nil then
		return
	end

	local prevControllerTypeEnum = self._ControllerTypeEnum[self.Player]
	local newControllerTypeEnum = Enums.getEnum("ControllerType", controllerType)

	if prevControllerTypeEnum == newControllerTypeEnum then
		return
	end

	self._ControllerTypeEnum[self.Player] = newControllerTypeEnum

	Network.fireServer("PlayerControllerTypeChanged", self.Player, newControllerTypeEnum)

	for callback, _ in self._ControllerTypeChangedCallbacks do
		callback(self.Player, controllerType)
	end
end

local function getClientControllerType(self, Player)
	Player = Player or self.Player

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if self._ControllerTypeEnum[Player] then
		return Enums.enumToName("ControllerType", self._ControllerTypeEnum[Player])
	end

	return DEFAULT_CONTROLLER_TYPE
end
local function onClientControllerTypeChangedConnect(self, callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	self._ControllerTypeChangedCallbacks[callback] = true

	for Player, controllerTypeEnum in self._ControllerTypeEnum do
		local controllerType = Enums.enumToName("ControllerType", controllerTypeEnum)
		callback(Player, controllerType)
	end

	return {
		Disconnect = function()
			self._ControllerTypeChangedCallbacks[callback] = nil
		end,
	}
end
local function initializeClientInput(self)
	self._ControllerTypeEnum[self.Player] = DEFAULT_CONTROLLER_TYPE_ENUM

	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(InputObject, gameProcessed)
		if gameProcessed then
			return
		end

		clientTapInput(self, InputObject)
		clientBeginInput(self, InputObject)
	end))
	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(InputObject, gameProcessed)
		if gameProcessed then
			return
		end

		clientTapInput(self, InputObject)
	end))
	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(InputObject, gameProcessed)
		if gameProcessed then
			return
		end

		clientEndInput(self, InputObject)
	end))

	self._Maid:GiveTask(Network.onClientEventConnect("PlayerControllerTypeChanged", self.Player, function(...)
		onPlayerControllerTypeChanged(self, ...)
	end))
	Network.fireServer("GetPlayersControllerTypeEnums", self.Player)
end

-- public
local function initializeClientInputModule()
	if DEFAULT_CONTROLLER_TYPE_ENUM == nil then
		error(`Config.DefaultControllerType is set to "{DEFAULT_CONTROLLER_TYPE}", which is not a ControllerType Enum`)
	end
end

return {
	-- Client class methods
	clientBeginInput = clientBeginInput,
	clientEndInput = clientEndInput,
	clientTapInput = clientTapInput,

	onClientControllerTypeChangedConnect = onClientControllerTypeChangedConnect,
	getClientControllerType = getClientControllerType,

	initializeClientInput = initializeClientInput,

	-- root
	initialize = initializeClientInputModule,
}
