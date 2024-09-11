-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

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
	end
end

return {
    new = newLobbyButtons,
}
