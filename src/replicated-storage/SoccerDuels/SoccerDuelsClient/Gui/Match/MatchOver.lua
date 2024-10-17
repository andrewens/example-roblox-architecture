-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function newMatchOverGui(self)
	local MatchOverGui = Assets.getExpectedAsset("MatchOverGui", "MainGui", self.MainGui)
	local MatchOverResultLabel = Assets.getExpectedAsset("MatchOverResultLabel", "MatchOverGui", MatchOverGui)
	local MatchOverLostGradient = Assets.getExpectedAsset("MatchOverLostGradient", "MatchOverGui", MatchOverGui)
	local MatchOverWonGradient = Assets.getExpectedAsset("MatchOverWonGradient", "MatchOverGui", MatchOverGui)
	local MatchOverDrawGradient = Assets.getExpectedAsset("MatchOverDrawGradient", "MatchOverGui", MatchOverGui)

	local function renderMatchResult(matchResult)
		MatchOverResultLabel.Text = string.upper(matchResult)

		MatchOverLostGradient.Enabled = (matchResult == "Lost")
		MatchOverWonGradient.Enabled = (matchResult == "Won")
		MatchOverDrawGradient.Enabled = (matchResult == "Draw")
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		MatchOverGui.Visible = (userInterfaceMode == "MatchOver")
		if not MatchOverGui.Visible then
			return
		end

		local playerTeamIndex = self:GetPlayerTeamIndex(self.Player)
		local PlayerWhoScoredLastGoal = self:GetPlayerWhoScoredLastGoal()

		if playerTeamIndex == nil or PlayerWhoScoredLastGoal == nil then
			renderMatchResult("Draw")
			return
		end

		local scoringPlayerTeamIndex = self:GetPlayerTeamIndex(PlayerWhoScoredLastGoal)
		if scoringPlayerTeamIndex == nil then
			renderMatchResult("Draw")
			return
		end

		if playerTeamIndex == scoringPlayerTeamIndex then
			renderMatchResult("Won")
			return
		end

		renderMatchResult("Lost")
	end)

	MatchOverGui.Visible = false
end

return {
	new = newMatchOverGui,
}
