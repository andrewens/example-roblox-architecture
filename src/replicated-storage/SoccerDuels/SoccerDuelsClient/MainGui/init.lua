-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

local LobbyButtons = require(script.LobbyButtons)
local ModalGui = require(script.ModalGui)
local ToastGui = require(script.ToastGui)

-- public
local function newMainGui(Client)
	local MainGui = Assets.cloneExpectedAsset("MainGui")

	LobbyButtons.new(Client, MainGui)
	ModalGui.new(Client, MainGui)
	ToastGui.new(Client, MainGui)

	MainGui.Parent = Client.Player.PlayerGui

	return MainGui
end
local function initializeMainGui()
	ModalGui.initialize()
end

return {
	new = newMainGui,
	initialize = initializeMainGui,
}
