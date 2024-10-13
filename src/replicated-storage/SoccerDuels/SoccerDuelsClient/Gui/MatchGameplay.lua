-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const
local GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE = {
	["MatchCountdown"] = true,
	["MatchGameplay"] = true,
	["Gameplay"] = true,
}
local TIMER_POLL_RATE = Config.getConstant("UserInterfaceCountdownTimerPollRateSeconds")

-- public / Client class methods
local function newMatchLoadingScreenGui(self)
	local GameplayGui = Assets.getExpectedAsset("MatchGameplayGui", "MainGui", self._MainGui)
	local MatchCounterTextLabel = Assets.getExpectedAsset("MatchCountdownTimerLabel", "MatchGameplayGui", GameplayGui)

	local UIMaid = Maid.new()

    self._Maid:GiveTask(UIMaid)

	local function updateCountdownTimer(dt)
		local timestamp = self:GetConnectedMapStateChangeTimestamp()
		local now = Time.getUnixTimestampMilliseconds()
		local deltaTime = math.ceil(math.max((timestamp - now) * 0.001, 0))

		MatchCounterTextLabel.Text = if deltaTime > 0 then deltaTime else ""
	end

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		GameplayGui.Visible = GAMEPLAY_GUI_IS_VISIBLE_DURING_UI_MODE[userInterfaceMode] or false

		-- match countdown timer
		MatchCounterTextLabel.Visible = userInterfaceMode == "MatchCountdown"

		if MatchCounterTextLabel.Visible then
			UIMaid:GiveTask(Utility.runServiceRenderSteppedConnect(TIMER_POLL_RATE, updateCountdownTimer))
		end
	end)

	GameplayGui.Visible = false

	UIAnimations.initializeTimer(self, MatchCounterTextLabel)
end

return {
	new = newMatchLoadingScreenGui,
}
