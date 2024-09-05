-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local ModalGui = require(script.ModalGui)

-- public
local function newMainGui(Client)
	-- var
	local MainGui
	local LobbyButtons
	local Modal

	-- init
	MainGui = Assets.cloneExpectedAsset("MainGui")
	LobbyButtons = Assets.getExpectedAsset("LobbyButtons", "MainGui", MainGui)
	Modal = ModalGui.new(Client, MainGui)

	for _, LobbyButton in LobbyButtons:GetChildren() do
		if not (LobbyButton:IsA("GuiButton")) then
			continue
		end

		LobbyButton.Activated:Connect(function()
			Client:ToggleModalVisibility(LobbyButton.Name)
		end)
	end

	Client:OnVisibleModalChangedConnect(function(visibleModalName)
		if visibleModalName == nil then
			Modal:Hide()
			return
		end

		Modal:ShowModal(visibleModalName)
	end)

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
