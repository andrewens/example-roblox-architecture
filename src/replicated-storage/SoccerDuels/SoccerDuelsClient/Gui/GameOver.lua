-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function newGameOverGui(self)
	local GameOverGui = Assets.getExpectedAsset("GameOverGui", "MainGui", self.MainGui)
	local GameOverMVPContainer = Assets.getExpectedAsset("GameOverMVPContainer", "GameOverGui", GameOverGui)

	local GameOverMVPUserNameLabel = Assets.getExpectedAsset("GameOverMVPUserNameLabel", "GameOverGui", GameOverGui)
	local GameOverMVPLevelLabel = Assets.getExpectedAsset("GameOverMVPLevelLabel", "GameOverGui", GameOverGui)

	local GameOverMVPGoalsLabel = Assets.getExpectedAsset("GameOverMVPGoalsLabel", "GameOverGui", GameOverGui)
	local GameOverMVPAssistsLabel = Assets.getExpectedAsset("GameOverMVPAssistsLabel", "GameOverGui", GameOverGui)
	local GameOverMVPTacklesLabel = Assets.getExpectedAsset("GameOverMVPTacklesLabel", "GameOverGui", GameOverGui)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		GameOverGui.Visible = (userInterfaceMode == "GameOver")

		if not GameOverGui.Visible then
			return
		end

		local playerTeamIndex = self:GetPlayerTeamIndex(self.Player)
		if playerTeamIndex == nil then
			return
		end

		local MVPPlayer = self:GetTeamMVP(playerTeamIndex)
		GameOverMVPContainer.Visible = (MVPPlayer ~= nil)

		if not GameOverMVPContainer.Visible then
			return
		end

		GameOverMVPUserNameLabel.Text = MVPPlayer.Name
		GameOverMVPLevelLabel.Text = self:GetAnyPlayerDataValue("Level", MVPPlayer)

		GameOverMVPGoalsLabel.Text = self:GetPlayerLeaderstat(MVPPlayer, "Goals")
		GameOverMVPAssistsLabel.Text = self:GetPlayerLeaderstat(MVPPlayer, "Assists")
		GameOverMVPTacklesLabel.Text = self:GetPlayerLeaderstat(MVPPlayer, "Tackles")
	end)

	GameOverGui.Visible = false
end

return {
	new = newGameOverGui,
}
