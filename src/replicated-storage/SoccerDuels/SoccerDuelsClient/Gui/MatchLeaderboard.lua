-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local ROBLOX_LEADERBOARD_ENABLED_FOR_UI_MODE = Config.getConstant("RobloxLeaderboardEnabledForTheseUserInterfaceModes")

-- public / Client class methods
local function newMatchLeaderboardGui(self)
	local LeaderboardScreenGui = Assets.cloneExpectedAsset("LeaderboardModal")

	self._Maid:GiveTask(LeaderboardScreenGui)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		Utility.setDefaultRobloxLeaderboardEnabled(ROBLOX_LEADERBOARD_ENABLED_FOR_UI_MODE[userInterfaceMode] or false)
	end)
	self:OnVisibleModalChangedConnect(function(visibleModalName)
        -- note that the default roblox leaderboard coregui must be disabled for Tab to work as a leaderboard keybind
		LeaderboardScreenGui.Enabled = (visibleModalName == "Leaderboard")
	end)

	LeaderboardScreenGui.Enabled = false
	LeaderboardScreenGui.Parent = self.Player.PlayerGui
end

return {
	new = newMatchLeaderboardGui,
}
