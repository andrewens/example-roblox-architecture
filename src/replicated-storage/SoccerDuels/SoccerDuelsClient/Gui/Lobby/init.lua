-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")
local ModalGuiFolder = script.Modals

local Assets = require(SoccerDuelsModule.AssetDependencies)
local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

local SettingsModalGui = require(ModalGuiFolder.Settings)
local AvailableMatchJoiningPadsGui = require(script.AvailableMatchJoiningPads)

-- public / Client class methods
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
		LobbyButtons.Visible = (userInterfaceMode == "Lobby")
	end)

	UIAnimations.initializePopup(self, LobbyButtons)

	SettingsModalGui.new(self)
	AvailableMatchJoiningPadsGui.new(self)

	LobbyGui.Visible = true
	LobbyGui.Parent.Visible = true -- 'Middle' (should be a frame)
end

return {
	new = newLobbyGui,
}
