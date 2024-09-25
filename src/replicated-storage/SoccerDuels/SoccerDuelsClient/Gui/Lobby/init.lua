-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")
local ModalGuiFolder = script.Modals

local Assets = require(SoccerDuelsModule.AssetDependencies)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

local SettingsModalGui = require(ModalGuiFolder.Settings)

-- public / Client class methods
local function destroyLobbyGui(self)
	SettingsModalGui.destroy(self)
end
local function newLobbyGui(self)
	local LobbyGui = Assets.getExpectedAsset("LobbyGui", "MainGui", self._MainGui)
	local LobbyButtons = Assets.getExpectedAsset("LobbyButtons", "LobbyGui", LobbyGui)

    for _, LobbyButton in LobbyButtons:GetChildren() do
		if not (LobbyButton:IsA("GuiButton")) then
			continue
		end

		LobbyButton.Activated:Connect(function()
			self:ToggleModalVisibility(LobbyButton.Name)
		end)

		UIAnimations.initializeButton(self, LobbyButton, {
			LiftButtonOnMouseOver = true,
		})
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		LobbyButtons.Visible = userInterfaceMode == "Lobby"
	end)

	UIAnimations.initializePopup(self, LobbyButtons)

	SettingsModalGui.new(self)

	LobbyGui.Visible = true
end

return {
	destroy = destroyLobbyGui,
	new = newLobbyGui,
}