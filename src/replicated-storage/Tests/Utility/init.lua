-- public / temporary fix for server tests accidentally disconnecting a real client
local serverFinishedTests, clientWaitUntilServerFinishedTests
do
	-- TODO currently the client will load before the tests finish running
	-- and some of the tests call disconnectAllPlayers(), which causes the
	-- freshly loaded client to immediately be disconnected and deloaded.
	-- the root fix of this is to create server instances so all that state
	-- is encapsulated in a single object. this is just a quick fix.

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
	local TestRemoteEvents = script.RemoteEvents

	function serverFinishedTests()
		SoccerDuels.resetTestingVariables()
		SoccerDuels.disconnectAllPlayers()

		TestRemoteEvents.TestsFinished.OnServerEvent:Connect(function(Player)
			TestRemoteEvents.TestsFinished:FireClient(Player)
		end)
		TestRemoteEvents.TestsFinished:FireAllClients()
	end
	function clientWaitUntilServerFinishedTests()
		local testsRunning = true
		TestRemoteEvents.TestsFinished.OnClientEvent:Connect(function()
			testsRunning = false
		end)
		TestRemoteEvents.TestsFinished:FireServer()

		while testsRunning do
			task.wait()
		end
	end
end

-- public
local function isInteger(value)
	return typeof(value) == "number" and math.floor(value) == value
end
local function tableContainsValue(Table, value)
	for k, v in Table do
		if v == value then
			return true
		end
	end

	return false
end
local function tableIsSubsetOfTable(SubsetTable, SupersetTable)
	if typeof(SubsetTable) == "table" and typeof(SupersetTable) == "table" then
		for k, v in SubsetTable do
			local s, msg = tableIsSubsetOfTable(v, SupersetTable[k])
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end

		return true
	end

	if SubsetTable ~= SupersetTable then
		return false, `{SubsetTable} != {SupersetTable}`
	end

	return true
end
local function tableShallowEqual(Table1, Table2)
	if typeof(Table1) == "table" and typeof(Table2) == "table" then
		for k, v in Table1 do
			if Table2[k] ~= v then
				return false, `{v} != {Table2[k]} (key='{k}')`
			end
		end

		for k, v in Table2 do
			if Table1[k] ~= v then
				return false, `{Table1[k]} != {v} (key='{k}')`
			end
		end

		return true
	end

	return Table1 == Table2, `{Table1} != {Table2}`
end
local function tableDeepEqual(Table1, Table2)
	if typeof(Table1) == "table" and typeof(Table2) == "table" then
		for k, v in Table1 do
			local s, msg = tableDeepEqual(v, Table2[k])
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end
		for k, v in Table2 do -- redundant, but avoids extra memory
			local s, msg = tableDeepEqual(Table1[k], v)
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end

		return true
	end

	if Table1 ~= Table2 then
		return false, `{Table1} != {Table2}`
	end

	return true
end

return {
	isInteger = isInteger,

	tableIsSubsetOfTable = tableIsSubsetOfTable,
	tableContainsValue = tableContainsValue,
	tableShallowEqual = tableShallowEqual,
	tableDeepEqual = tableDeepEqual,

	-- temp fix
	serverFinishedTests = serverFinishedTests,
	clientWaitUntilServerFinishedTests = clientWaitUntilServerFinishedTests,
}
