-- dependency
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local MockHumanoid = require(MockInstanceModule.Humanoid)
local MockPart = require(MockInstanceModule.Part)

local SpawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)

-- public / MockCharacter class methods
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

-- MockCharacter class constructor
return function()
	local HumanoidRootPart = MockPart()
	HumanoidRootPart.Name = "HumanoidRootPart"
	HumanoidRootPart.Position = SpawnLocation.Position + Vector3.new(0, 3, 0)

	return {
		-- properties
		Name = "MockCharacter",
		Parent = nil,

		-- methods
		Destroy = destroyCharacter,
		FindFirstChild = findFirstChild,
		GetDescendants = getDescendants,
		MoveTo = moveTo,
		PivotTo = pivotTo,
		GetPivot = getPivot,

		-- children
		Humanoid = MockHumanoid(),
		HumanoidRootPart = HumanoidRootPart,
	}
end
