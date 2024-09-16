-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local MainGuiModule = script:FindFirstAncestor("MainGui")

local Assets = require(SoccerDuelsModule.AssetDependencies)

local UIAnimations = require(MainGuiModule.UIAnimations)

-- public
local function newLobbyButtons(self)
    local LobbyButtons = Assets.getExpectedAsset("LobbyButtons", "MainGui", self._MainGui)

    for _, LobbyButton in LobbyButtons:GetChildren() do
		if not (LobbyButton:IsA("GuiButton")) then
			continue
		end

		LobbyButton.Activated:Connect(function()
			self:ToggleModalVisibility(LobbyButton.Name)
		end)

		UIAnimations.initializeButton(LobbyButton)
	end
end

return {
    new = newLobbyButtons,
}
