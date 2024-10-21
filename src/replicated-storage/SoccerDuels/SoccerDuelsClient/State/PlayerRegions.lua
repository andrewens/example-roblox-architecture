-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- protected / Network methods
local function onPlayerRegionCodeChanged(self, Player, countryRegionCodeEnum)
	self._PlayerCountryRegionCodeEnum[Player] = countryRegionCodeEnum
end

-- public / Client class methods
local function getAnyPlayerRegion(self, Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local countryRegionCodeEnum = self._PlayerCountryRegionCodeEnum[Player]
	if countryRegionCodeEnum == nil then
		return nil
	end

	return Enums.enumToName("CountryRegionCode", countryRegionCodeEnum)
end
local function initializePlayerRegionsClientModule(self)
	self.Maid:GiveTask(Network.onClientEventConnect("PlayerCountryRegionCodeChanged", self.Player, function(...)
		onPlayerRegionCodeChanged(self, ...)
	end))
end

return {
	getAnyPlayerRegion = getAnyPlayerRegion,
	initialize = initializePlayerRegionsClientModule,
}
