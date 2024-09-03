-- var
local MaidMetatable

-- private
local function isValidTask(value)
	return typeof(value) == "Instance"
		or typeof(value) == "RBXScriptSignal"
        or typeof(value) == "function"
		or (typeof(value) == "table" and typeof(value.Destroy) == "function")
end
local function cleanTask(task)
    if typeof(task) == "function" then
        task()
    elseif typeof(task) == "RBXScriptSignal" then
        task:Disconnect()
    else
        task:Destroy()
    end
end

-- public / Maid class methods
local function giveMaidTask(self, task)
	if not (isValidTask(task)) then
		error(`{task} is not a valid task!`)
	end

	table.insert(self._Tasks, task)
end
local function cleanUpMaidTasks(self)
	for _, task in self._Tasks do
		cleanTask(task)
	end
	self._Tasks = {}
end

-- public
local function newMaid()
	local self = {}
	self._Tasks = {}

	setmetatable(self, MaidMetatable)

	return self
end
local function initializeMaids()
	local MaidClassMethods = {
		GiveTask = giveMaidTask,
		DoCleaning = cleanUpMaidTasks,
		Destroy = cleanUpMaidTasks,
	}
	MaidMetatable = { __index = MaidClassMethods }
end

return {
	new = newMaid,
	initialize = initializeMaids,
}
