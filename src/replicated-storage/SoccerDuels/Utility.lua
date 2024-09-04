-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

-- public
local function tableDeepCopy(Table)
	if typeof(Table) == "table" then
		local Copy = {}

		for k, v in Table do
			Copy[k] = tableDeepCopy(v)
		end

		return Copy
	end

	return Table
end
local function isA(value, className)
	return (typeof(value) == "Instance" or typeof(value) == "table") and value:IsA(className)
end
local function organizeDependenciesServerOnly()
	for _, RbxInstance in StarterGui:GetChildren() do
		RbxInstance.Parent = ReplicatedStorage.UserInterface
	end

	local SoccerDuelsServerModule = SoccerDuelsModule:FindFirstChild("SoccerDuelsServer")
	SoccerDuelsServerModule.Parent = ServerScriptService
end

return {
	tableDeepCopy = tableDeepCopy,
	isA = isA,
	organizeDependencies = organizeDependenciesServerOnly,
}
