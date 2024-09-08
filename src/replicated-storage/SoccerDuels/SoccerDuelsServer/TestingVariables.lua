-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local DEFAULT_TESTING_VARIABLES = Config.getConstant("TestingVariables")

-- var
local TestingVariables = if TESTING_MODE then table.clone(DEFAULT_TESTING_VARIABLES) else {}

-- public
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
local function setTestingModeVariable(variableName, newValue)
	if not TESTING_MODE then
		error(`SoccerDuels API can't set test mode variables when not in TestingMode`)
	end

	if TestingVariables[variableName] == nil then
		error(`There's no TestingVariable named "{variableName}"`)
	end
	if typeof(TestingVariables[variableName]) ~= typeof(newValue) then
		error(
			`TestingVariable "{variableName}" is a {typeof(TestingVariables[variableName])}, not a {typeof(newValue)}`
		)
	end

	TestingVariables[variableName] = newValue
end
local function getTestingModeVariable(variableName)
	return TestingVariables[variableName]
end
local function resetTestingModeVariables()
	if not TESTING_MODE then
		error(`SoccerDuels API can't reset test mode variables when not in TestingMode`)
	end

	TestingVariables = table.clone(DEFAULT_TESTING_VARIABLES)
end

return {
	wait = testingModeWait,
	setVariable = setTestingModeVariable,
	getVariable = getTestingModeVariable,
	resetVariables = resetTestingModeVariables,
}
