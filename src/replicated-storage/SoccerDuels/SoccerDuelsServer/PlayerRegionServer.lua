-- dependency
local LocalizationService = game:GetService("LocalizationService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local NUM_TRIES = Config.getConstant("GetPlayerCountryRegionCodeNumTries")

-- var
local PlayerRegionCodes = {} -- Player --> int countryRegionCodeEnum

-- private
local function getPlayerCountryRegionCode(Player)
	-- no asyncs allowed in testing mode >:(
	if TESTING_MODE then
		if Player.UserId == 9792010 then
			return "US"
		end

		local enum = Enums.getRandomEnumOfType("CountryRegionCode")
		return Enums.enumToName("CountryRegionCode", enum)
	end

	for i = 1, NUM_TRIES do
		local s, output = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(Player)
		end)

		if s then
			return output or "None"
		end

		task.wait()
	end

	return "None"
end

-- public
local function getPlayerRegion(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local countryRegionCodeEnum = PlayerRegionCodes[Player]
	if countryRegionCodeEnum == nil then
		return nil
	end

	return Enums.enumToName("CountryRegionCode", countryRegionCodeEnum)
end
local function playerDataLoaded(Player)
	for OtherPlayer, countryRegionCodeEnum in PlayerRegionCodes do
		Network.fireClient("PlayerCountryRegionCodeChanged", Player, OtherPlayer, countryRegionCodeEnum)
	end

	local countryRegionCode = getPlayerCountryRegionCode(Player)
	local playerCountryRegionCodeEnum = Enums.getEnum("CountryRegionCode", countryRegionCode)

	PlayerRegionCodes[Player] = playerCountryRegionCodeEnum
	Network.fireAllClients("PlayerCountryRegionCodeChanged", Player, playerCountryRegionCodeEnum)
end
local function disconnectPlayer(Player)
	PlayerRegionCodes[Player] = nil
	Network.fireAllClients("PlayerCountryRegionCodeChanged", Player, nil)
end

return {
	getPlayerRegion = getPlayerRegion,

	playerDataLoaded = playerDataLoaded,
	disconnectPlayer = disconnectPlayer,
}
