-- dependency
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local Maid = require(SoccerDuelsModule.Maid)

-- public
local function setDefaultRobloxLeaderboardEnabled(isEnabled)
	if not (typeof(isEnabled) == "boolean") then
		error(`{isEnabled} is not a boolean!`)
	end
	if RunService:IsServer() then
		return
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, isEnabled)
end
local function convertInstanceIntoModel(RbxInstance)
	if not (typeof(RbxInstance) == "Instance") then
		error(`{RbxInstance} is not an Instance!`)
	end

	if RbxInstance:IsA("Model") then
		return RbxInstance
	end

	local Model = Instance.new("Model")

	for _, Child in RbxInstance:GetChildren() do
		Child.Parent = Model
	end

	Model.Name = RbxInstance.Name
	Model.Parent = RbxInstance.Parent

	RbxInstance:Destroy()

	return Model
end
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
	-- consumed by the client, despite connecting to the remote event after the tests finish.
	return RunService:IsClient() and typeof(Player) == "table"
end
local function runServiceRenderSteppedConnect(rate, callback)
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

	callback(0.0167) -- 0.0167 = 1/60 which is the ideal frame rate

	local deltaTime = 0
	local Event = if RunService:IsServer() then RunService.Heartbeat else RunService.RenderStepped
	return Event:Connect(function(dt)
		deltaTime += dt
		if deltaTime < rate then
			return
		end

		callback(deltaTime)
		deltaTime = 0
	end)
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
local function playerIsInGame(Player)
	if not isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	return typeof(Player) == "table" or Players:FindFirstChild(Player.Name) ~= nil
end
local function cloneCharacter(Character)
	local ClonedCharacter = Instance.new("Model")
	ClonedCharacter.Name = Character.Name

	for _, Child in Character:GetChildren() do
		Child:Clone().Parent = ClonedCharacter
	end

	return ClonedCharacter
end
local function setPlayerCharacterAnchored(Player, isAnchored)
	if not isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(isAnchored) == "boolean") then
		error(`{isAnchored} is not a boolean!`)
	end

	if Player.Character == nil then
		return
	end

	local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart == nil then
		return
	end

	HumanoidRootPart.Anchored = isAnchored
end
local function getPlayerCharacterCFrame(Player)
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

	return HumanoidRootPart.CFrame
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

	local Connections = {} -- Player --> RBXScriptSignal or whatever it is

	Connections[1] = Players.PlayerAdded:Connect(function(Player)
		Connections[Player] = Player.CharacterAdded:Connect(function(Char)
			callback(Player, Char)
		end)
	end)

	Connections[2] = Players.PlayerRemoving:Connect(function(Player)
		local conn = Connections[Player]
		if conn == nil then
			return
		end

		conn:Disconnect()
		Connections[Player] = nil
	end)

	for _, Player in Players:GetPlayers() do
		Connections[Player] = Player.CharacterAdded:Connect(function(Char)
			callback(Player, Char)
		end)

		if Player.Character then
			callback(Player, Player.Character)
		end
	end

	return {
		Disconnect = function()
			for _, conn in Connections do
				conn:Disconnect()
			end
			Connections = nil
		end,
	}
end
local function onCharacterAppearanceLoadedConnect(callback)
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAppearanceLoaded:Connect(function(Char)
			callback(Player, Char)
		end)
	end)

	for _, Player in Players:GetPlayers() do
		Player.CharacterAppearanceLoaded:Connect(function(Char)
			callback(Player, Char)
		end)

		if Player.Character and Player:HasAppearanceLoaded() then
			callback(Player, Player.Character)
		end
	end
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

return {
	setDefaultRobloxLeaderboardEnabled = setDefaultRobloxLeaderboardEnabled,
	convertInstanceIntoModel = convertInstanceIntoModel,

	dictionaryToArray = dictionaryToArray,
	tableDeepCopy = tableDeepCopy,
	tableCount = tableCount,
	isInteger = isInteger,
	isA = isA,

	playerCharacterIsInsideSpherePart = playerCharacterIsInsideSpherePart,
	getPlayerCharacterPosition = getPlayerCharacterPosition,
	setPlayerCharacterAnchored = setPlayerCharacterAnchored,
	getPlayerCharacterCFrame = getPlayerCharacterCFrame,
	cloneCharacter = cloneCharacter,
	playerIsInGame = playerIsInGame,
	weldPartToPart = weldPartToPart,

	onCharacterAppearanceLoadedConnect = onCharacterAppearanceLoadedConnect,
	runServiceRenderSteppedConnect = runServiceRenderSteppedConnect,
	runServiceSteppedConnect = runServiceSteppedConnect,
	onCharacterLoadedConnect = onCharacterLoadedConnect,
	onPartTouchedConnect = onPartTouchedConnect,
	onPlayerDiedConnect = onPlayerDiedConnect,

	shouldIgnoreMockPlayerFromServerTests = shouldIgnoreMockPlayerFromServerTests,
}
