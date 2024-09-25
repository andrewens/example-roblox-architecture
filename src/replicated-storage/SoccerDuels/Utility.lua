-- dependency
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

-- public
local function onPartTouchedConnect(Part, debounceWaitSeconds, callback)
	if callback == nil then -- support passing just a callback
		callback = debounceWaitSeconds
		debounceWaitSeconds = 0
	end

	if not (typeof(Part) == "Instance" and Part:IsA("BasePart")) then
		error(`{Part} is not a BasePart!`)
	end
	if not (typeof(debounceWaitSeconds) == "number" and debounceWaitSeconds >= 0) then
		error(`{debounceWaitSeconds} is not a positive number!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local debounceEndsTimestamp = 0
	return Part.Touched:Connect(function(TouchingPart)
		if os.clock() < debounceEndsTimestamp then
			return
		end
		debounceEndsTimestamp = os.clock() + debounceWaitSeconds

		callback(TouchingPart)
	end)
end
local function weldPartToPart(WeldedPart, ParentPart)
	WeldedPart.CFrame = ParentPart.CFrame

	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = ParentPart
	Weld.Part1 = WeldedPart
	Weld.Name = `Weld to "{ParentPart}"`
	Weld.Parent = WeldedPart

	return Weld
end
local function shouldIgnoreMockPlayerFromServerTests(Player)
	-- TODO this is a band-aid to a really annoying issue: previously fired RemoteEvents queue up and still get
	-- consume by the client, despite connecting to the remote event after the tests finish.
	return RunService:IsClient() and typeof(Player) == "table"
end
local function runServiceSteppedConnect(rate, callback)
	if callback == nil then -- support passing just a callback
		callback = rate
		rate = 0
	end

	if not (typeof(rate) == "number" and rate >= 0) then
		error(`{rate} is not a positive number!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local deltaTime = 0
	return RunService.Stepped:Connect(function(t, dt)
		deltaTime += dt
		if deltaTime < rate then
			return
		end

		callback(t, deltaTime)
		deltaTime = 0
	end)
end
local function dictionaryToArray(Dictionary)
	local Array = {}
	for k, v in Dictionary do
		table.insert(Array, k)
	end
	return Array
end
local function tableCount(Table)
	local count = 0
	for k, v in Table do
		count += 1
	end
	return count
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
	return (typeof(value) == "Instance" or typeof(value) == "table")
		and (typeof(value.IsA) == "function")
		and value:IsA(className)
end
local function getPlayerCharacterPosition(Player)
	if not isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local Character = Player.Character
	if Character == nil or Character.Parent == nil then
		return nil
	end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart == nil then
		return nil
	end

	return HumanoidRootPart.Position
end
local function playerCharacterIsInsideSpherePart(Player, SpherePart, padding)
	padding = padding or 0

	if not isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not isA(SpherePart, "BasePart") then
		error(`{SpherePart} is not a BasePart!`)
	end
	if not (typeof(padding) == "number") then
		error(`{padding} is not a number!`)
	end

	local charPosition = getPlayerCharacterPosition(Player)
	if charPosition == nil then
		return false
	end

	local sphereRadius = padding + 0.5 * SpherePart.Size.X
	local offset = charPosition - SpherePart.Position

	return offset:Dot(offset) <= sphereRadius * sphereRadius
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
	isA = isA,
	isInteger = isInteger,
	tableCount = tableCount,
	tableDeepCopy = tableDeepCopy,
	dictionaryToArray = dictionaryToArray,

	weldPartToPart = weldPartToPart,
	onPartTouchedConnect = onPartTouchedConnect,
	playerCharacterIsInsideSpherePart = playerCharacterIsInsideSpherePart,

	onPlayerDiedConnect = onPlayerDiedConnect,
	onCharacterLoadedConnect = onCharacterLoadedConnect,
	runServiceSteppedConnect = runServiceSteppedConnect,
	getPlayerCharacterPosition = getPlayerCharacterPosition,

	organizeDependencies = organizeDependenciesServerOnly,
	shouldIgnoreMockPlayerFromServerTests = shouldIgnoreMockPlayerFromServerTests,
}
