-- dependency
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

--[[ NORMAL MODE ]]
if RunService:IsClient() or not TESTING_MODE then
	local function getUnixTimestamp()
		return DateTime.now().UnixTimestamp
	end
	local function getUnixTimestampMilliseconds()
		return DateTime.now().UnixTimestampMillis
	end

	return {
		getUnixTimestamp = getUnixTimestamp,
		getUnixTimestampMilliseconds = getUnixTimestampMilliseconds,
	}
end

--[[ TESTING MODE ]]
local SoccerDuelsServerModule = SoccerDuelsModule:FindFirstChild("SoccerDuelsServer")

local TestingVariables = require(SoccerDuelsServerModule.TestingVariables)

-- public
local function getUnixTimestamp()
	return DateTime.now().UnixTimestamp + TestingVariables.getVariable("ExtraSecondsInTimestamp")
end
local function getUnixTimestampMilliseconds()
	return DateTime.now().UnixTimestampMillis + TestingVariables.getVariable("ExtraSecondsInTimestamp") * 1E3
end

return {
	getUnixTimestamp = getUnixTimestamp,
	getUnixTimestampMilliseconds = getUnixTimestampMilliseconds,
}
