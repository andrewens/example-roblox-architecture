-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local AssetDependencies = require(SoccerDuelsModule.AssetDependencies)
local ModalGui = require(script.ModalGui)

-- public
local function newWindowsGui(Client)
	-- var
	local WindowsGui
	local LobbyButtons
	local Modal

	-- init
	WindowsGui = AssetDependencies.cloneExpectedAsset("WindowsGui")
	LobbyButtons = AssetDependencies.getExpectedAsset("LobbyButtons", "WindowsGui", WindowsGui)
	Modal = ModalGui.new(Client, WindowsGui)

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

	WindowsGui.Parent = Client.Player.PlayerGui

	return WindowsGui
end
local function initializeWindowsGui()
	ModalGui.initialize()
end

return {
	new = newWindowsGui,
	initialize = initializeWindowsGui,
}
