-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local DEFAULT_TESTING_VARIABLES = Config.getConstant("TestingVariables")

-- var
local TestingVariables = if TESTING_MODE then table.clone(DEFAULT_TESTING_VARIABLES) else {}

-- public
local function addExtraSecondsForTesting(extraSeconds)
	if not TESTING_MODE then
		error(`SoccerDuels API can't set test mode variables when not in TestingMode`)
	end
	if not (typeof(extraSeconds) == "number") then
		error(`{extraSeconds} is not a number!`)
	end

	TestingVariables.ExtraSecondsInTimestamp += extraSeconds
end
local function testingModeWait(seconds)
	seconds = seconds or 0
	if not (typeof(seconds) == "number") then
		error(`{seconds} is not a number!`)
	end

	if TestingVariables.TimeTravel then
		return seconds
	end

	return task.wait(seconds)
end
local function decrementTestingModeVariable(variableName)
	if not TESTING_MODE then
		error(`SoccerDuels API can't decrement test mode variables when not in TestingMode`)
	end

	local Path = string.split(variableName, "/")
	local Table = TestingVariables
	local key = Path[#Path]

	for i = 1, #Path - 1 do
		Table = Table[Path[i]]
		if Table == nil then
			error(`There's no TestingVariable with path "{variableName}"`)
		end
	end

	if Table[key] == nil then
		error(`There's no TestingVariable with path "{variableName}"`)
	end
	if typeof(Table[key]) ~= "number" then
		error(`TestingVariable "{variableName}" is not a number and can't be decremented!}`)
	end

	Table[key] -= 1
end
local function setTestingModeVariable(variableName, newValue)
	if not TESTING_MODE then
		error(`SoccerDuels API can't set test mode variables when not in TestingMode`)
	end

	local Path = string.split(variableName, "/")
	local Table = TestingVariables
	local key = Path[#Path]

	for i = 1, #Path - 1 do
		Table = Table[Path[i]]
		if Table == nil then
			error(`There's no TestingVariable with path "{variableName}"`)
		end
	end

	if Table[key] == nil then
		error(`There's no TestingVariable with path "{variableName}"`)
	end
	if typeof(Table[key]) ~= typeof(newValue) then
		error(`TestingVariable "{variableName}" is a {typeof(Table[key])}, not a {typeof(newValue)}`)
	end

	Table[key] = newValue
end
local function getTestingModeVariable(variableName)
	local value = TestingVariables

	for _, key in string.split(variableName, "/") do
		value = value[key]
		if value == nil then
			return nil
		end
	end

	return value
end
local function resetTestingModeVariables()
	if not TESTING_MODE then
		error(`SoccerDuels API can't reset test mode variables when not in TestingMode`)
	end

	TestingVariables = table.clone(DEFAULT_TESTING_VARIABLES)
end

return {
	addExtraSecondsForTesting = addExtraSecondsForTesting,
	decrementVariable = decrementTestingModeVariable,
	resetVariables = resetTestingModeVariables,
	setVariable = setTestingModeVariable,
	getVariable = getTestingModeVariable,
	wait = testingModeWait,
}
