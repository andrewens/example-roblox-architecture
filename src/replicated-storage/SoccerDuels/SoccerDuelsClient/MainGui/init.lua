-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

local LobbyButtons = require(script.LobbyButtons)
local ModalGui = require(script.ModalGui)
local TestingModeGui = require(script.TestingModeGui)
local ToastGui = require(script.ToastGui)

-- public / Client class methods
local function newMainGui(self)
	self._MainGui = Assets.cloneExpectedAsset("MainGui")

	TestingModeGui.new(self)
	LobbyButtons.new(self)
	ModalGui.new(self)
	ToastGui.new(self)

	self._MainGui.Parent = self.Player.PlayerGui
	self._Maid:GiveTask(self._MainGui)
end

-- public
local function initializeMainGui()
	ModalGui.initialize()
end

return {
	new = newMainGui,
	initialize = initializeMainGui,
}
