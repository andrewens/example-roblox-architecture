-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Enums = require(SoccerDuelsModule.Enums)

local MatchLoadingScreenGui = require(script.MatchLoadingScreen)
local MatchLeaderboardGui = require(script.MatchLeaderboard)
local MatchJoiningPadGui = require(script.MatchJoiningPad)
local MatchGameplayGui = require(script.MatchGameplay)
local CharacterHeadGui = require(script.CharacterHead)
local TestingModeGui = require(script.TestingMode)
local MapVotingGui = require(script.MapVoting)
local GameOverGui = require(script.GameOver)
local LobbyGui = require(script.Lobby)
local ToastGui = require(script.Toast)

-- public / Client class methods
local function destroyClientGui(self)
	if self.MainGui then
		self.MainGui:Destroy()
		self.MainGui = nil
	end
end
local function newClientGui(self)
	self:OnPlayerSaveDataLoadedConnect(function(_)
		if self.MainGui then
			return -- (if for some weird reason, LoadPlayerDataAsync() gets called more than once)
		end

		self.MainGui = Assets.cloneExpectedAsset("MainGui")
		self.MainGui.Parent = self.Player.PlayerGui

		MatchLoadingScreenGui.new(self)
		MatchLeaderboardGui.new(self)
		MatchJoiningPadGui.new(self)
		MatchGameplayGui.new(self)
		CharacterHeadGui.new(self)
		TestingModeGui.new(self)
		MapVotingGui.new(self)
		GameOverGui.new(self)
		LobbyGui.new(self)
		ToastGui.new(self)
	end)
end

return {
	destroy = destroyClientGui,
	new = newClientGui,
}
