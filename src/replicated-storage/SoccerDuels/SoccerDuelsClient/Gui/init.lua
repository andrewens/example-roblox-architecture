-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Enums = require(SoccerDuelsModule.Enums)

local MatchLoadingScreenGui = require(script.MatchLoadingScreen)
local MatchJoiningPadGui = require(script.MatchJoiningPad)
local CharacterHeadGui = require(script.CharacterHead)
local TestingModeGui = require(script.TestingMode)
local MapVotingGui = require(script.MapVoting)
local LobbyGui = require(script.Lobby)
local ToastGui = require(script.Toast)

-- public / Client class methods
local function destroyClientGui(self)
	if self._MainGui then
		self._MainGui:Destroy()
		self._MainGui = nil
	end
end
local function newClientGui(self)
	self:OnPlayerSaveDataLoadedConnect(function(_)
		if self._MainGui then
			return -- (if for some weird reason, LoadPlayerDataAsync() gets called more than once)
		end

		self._MainGui = Assets.cloneExpectedAsset("MainGui")
		self._MainGui.Parent = self.Player.PlayerGui

		MatchLoadingScreenGui.new(self)
		MatchJoiningPadGui.new(self)
		CharacterHeadGui.new(self)
		TestingModeGui.new(self)
		MapVotingGui.new(self)
		LobbyGui.new(self)
		ToastGui.new(self)
	end)
end

return {
	destroy = destroyClientGui,
	new = newClientGui,
}
