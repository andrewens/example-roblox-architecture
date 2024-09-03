-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local AssetDependencies = require(SoccerDuelsModule.AssetDependencies)

-- public
local function newWindowsGui(Client)
	local WindowsGui = AssetDependencies.cloneExpectedAsset("WindowsGui")
	WindowsGui.Parent = Client.Player.PlayerGui

	local LobbyButtons = AssetDependencies.getExpectedAsset("LobbyButtons", "WindowsGui", WindowsGui)

	for _, LobbyButton in LobbyButtons:GetChildren() do
		if not (LobbyButton:IsA("GuiButton")) then
			continue
		end

		LobbyButton.Activated:Connect(function()
			Client:ToggleModalVisibility(LobbyButton.Name)
		end)
	end
end
local function initializeWindowsGui() end

return {
	new = newWindowsGui,
	initialize = initializeWindowsGui,
}
