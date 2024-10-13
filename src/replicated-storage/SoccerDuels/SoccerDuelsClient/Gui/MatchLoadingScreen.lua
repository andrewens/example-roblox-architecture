-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Maid = require(SoccerDuelsModule.Maid)

local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const
local DELAY_BEFORE_REMOVING_LOADING_SCREEN = 1

-- public / Client class methods
local function newMatchLoadingScreenGui(self)
	local LoadingScreenGui = Assets.cloneExpectedAsset("MapLoadingScreen")
	local BufferingImage =
		Assets.getExpectedAsset("MapLoadingScreenBufferingIcon", "MapLoadingScreen", LoadingScreenGui)

	LoadingScreenGui.Enabled = false
	LoadingScreenGui.Parent = self.Player.PlayerGui

	local UIMaid = Maid.new()

	self._Maid:GiveTask(LoadingScreenGui)
	self._Maid:GiveTask(UIMaid)

	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		if userInterfaceMode == "LoadingMap" then
			LoadingScreenGui.Enabled = true

			UIAnimations.initializeBufferingAnimation(self, BufferingImage)

			UIMaid:GiveTask(function()
				UIAnimations.destroyBufferingAnimation(self, BufferingImage)
			end)

			return
		end

		if LoadingScreenGui.Enabled then
			task.delay(DELAY_BEFORE_REMOVING_LOADING_SCREEN, function()
				LoadingScreenGui.Enabled = false
			end)
		end
	end)
end

return {
	new = newMatchLoadingScreenGui,
}
