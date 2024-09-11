-- dependency
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

-- public
local function getUnixTimestampMilliseconds()
	return DateTime.now().UnixTimestampMillis
end
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
local function isInteger(value)
	return typeof(value) == "number" and math.floor(value) == value
end
local function isA(value, className)
	return (typeof(value) == "Instance" or typeof(value) == "table") and value:IsA(className)
end
local function onCharacterLoadedConnect(callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local conn = Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function(Char)
			callback(Player, Char)
		end)
	end)

	for _, Player in Players:GetPlayers() do
		if Player.Character then
			callback(Player, Player.Character)
		end
	end

	return conn
end
local function onPlayerDiedConnect(Player, callback)
	local charAdded = function(Char)
		Char.Humanoid.Died:Connect(function()
			callback()
		end)

		if Char.Humanoid.Health <= 0 then
			callback()
		end
	end

	local conn = Player.CharacterAdded:Connect(charAdded)

	if Player.Character then
		charAdded(Player.Character)
	end

	return conn
end
local function organizeDependenciesServerOnly()
	for _, RbxInstance in StarterGui:GetChildren() do
		RbxInstance.Parent = ReplicatedStorage.UserInterface
	end

	local CharacterGuiTemplate = workspace:FindFirstChild("CharacterGuiTemplate")
	if CharacterGuiTemplate then
		CharacterGuiTemplate.Parent = ReplicatedStorage.UserInterface
	end

	local SoccerDuelsServerModule = SoccerDuelsModule:FindFirstChild("SoccerDuelsServer")
	SoccerDuelsServerModule.Parent = ServerScriptService
end

return {
	getUnixTimestampMilliseconds = getUnixTimestampMilliseconds,

	tableDeepCopy = tableDeepCopy,
	isInteger = isInteger,
	isA = isA,

	onPlayerDiedConnect = onPlayerDiedConnect,
	onCharacterLoadedConnect = onCharacterLoadedConnect,
	organizeDependencies = organizeDependenciesServerOnly,
}
