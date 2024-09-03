-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local AssetDependencies = require(SoccerDuelsModule.AssetDependencies)

-- public
local function newWindowsGui(Client)
	-- var
	local WindowsGui
	local LobbyButtons
	local ModalFrames
	local VisibleModalFrame

	-- init
	WindowsGui = AssetDependencies.cloneExpectedAsset("WindowsGui")
	LobbyButtons = AssetDependencies.getExpectedAsset("LobbyButtons", "WindowsGui", WindowsGui)
	ModalFrames = AssetDependencies.getExpectedAsset("ModalFrames", "WindowsGui", WindowsGui)

	for _, LobbyButton in LobbyButtons:GetChildren() do
		if not (LobbyButton:IsA("GuiButton")) then
			continue
		end

		LobbyButton.Activated:Connect(function()
			Client:ToggleModalVisibility(LobbyButton.Name)
		end)
	end

	Client:OnVisibleModalChangedConnect(function(visibleModalName)
		if VisibleModalFrame then
			VisibleModalFrame.Visible = false
			VisibleModalFrame = nil
		end

		if visibleModalName then
			VisibleModalFrame = ModalFrames:FindFirstChild(visibleModalName)
			if VisibleModalFrame == nil then
				error(`There's no ModalFrame named "{visibleModalName}"`)
			end

			VisibleModalFrame.Visible = true
		end
	end)

	WindowsGui.Parent = Client.Player.PlayerGui

	return WindowsGui
end
local function initializeWindowsGui() end

return {
	new = newWindowsGui,
	initialize = initializeWindowsGui,
}
