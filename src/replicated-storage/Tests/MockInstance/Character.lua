-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local MockHumanoid = require(MockInstanceModule.Humanoid)
local MockPart = require(MockInstanceModule.Part)

local SpawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)

-- public / MockCharacter class methods
local newCharacter
local function setPrimaryPartCFrame(self, cf)
	if not (typeof(cf) == "CFrame") then
		error(`{cf} is not a CFrame!`)
	end

	self.HumanoidRootPart.CFrame = cf
end
local function moveTo(self, position)
	if not (typeof(position) == "Vector3") then
		error(`{position} is not a Vector3!`)
	end

	self.HumanoidRootPart.Position = position
end
local function getPivot(self)
	return CFrame.new(self.HumanoidRootPart.Position)
end
local function pivotTo(self, cf)
	if not (typeof(cf) == "CFrame") then
		error(`{cf} is not a CFrame!`)
	end

	self.HumanoidRootPart.CFrame = cf
end
local function getDescendants(self)
	return {
		self.Humanoid,
		self.HumanoidRootPart,
	}
end
local function findFirstChild(self, childName)
	return self[childName]
end
local function cloneCharacter(self)
	return newCharacter({
		HumanoidRootPart = self.HumanoidRootPart:Clone(),
		Humanoid = self.Humanoid:Clone(),
		Name = self.Name,
	})
end
local function destroyCharacter(self)
	self.Parent = nil
	if self.Humanoid then
		self.Humanoid:Destroy()
		self.Humanoid = nil
	end
	if self.HumanoidRootPart then
		self.HumanoidRootPart:Destroy()
		self.HumanoidRootPart = nil
	end
end
function newCharacter(InputData)
	InputData = InputData or {}

	if InputData.HumanoidRootPart == nil then
		InputData.HumanoidRootPart = MockPart()
		InputData.HumanoidRootPart.Name = "HumanoidRootPart"
		InputData.HumanoidRootPart.Position = SpawnLocation.Position + Vector3.new(0, 3, 0)
	end
	InputData.HumanoidRootPart.Parent = workspace --> this is required for welds to update part positions when we move connected parts

	if InputData.Humanoid == nil then
		InputData.Humanoid = MockHumanoid()
	end

	return {
		-- properties
		Name = InputData.Name or "MockCharacter",
		Parent = nil,

		-- methods
		Clone = cloneCharacter,
		Destroy = destroyCharacter,
		FindFirstChild = findFirstChild,
		GetDescendants = getDescendants,
		SetPrimaryPartCFrame = setPrimaryPartCFrame,
		MoveTo = moveTo,
		PivotTo = pivotTo,
		GetPivot = getPivot,

		-- children
		Humanoid = InputData.Humanoid ,
		HumanoidRootPart = InputData.HumanoidRootPart,
	}
end

-- MockCharacter class constructor
return newCharacter
