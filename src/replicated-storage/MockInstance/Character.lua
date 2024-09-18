-- dependency
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local MockHumanoid = require(MockInstanceModule.Humanoid)
local MockPart = require(MockInstanceModule.Part)

-- public / MockCharacter class methods
local function getPivot(self)
    return CFrame.new(self.HumanoidRootPart.Position)
end
local function moveTo(self, position)
    if not (typeof(position) == "Vector3") then
        error(`{position} is not a Vector3!`)
    end

    self.HumanoidRootPart.Position = position
end
local function findFirstChild(self, childName)
    return self[childName]
end
local function destroyCharacter(self)
    self.Parent = nil
    self.Humanoid:Destroy()
    self.Humanoid = nil
end

-- MockCharacter class constructor
return function()
    return {
        -- properties
        Name = "MockCharacter",
        Parent = nil,

        -- methods
        Destroy = destroyCharacter,
        FindFirstChild = findFirstChild,
        MoveTo = moveTo,
        GetPivot = getPivot,

        -- children
        Humanoid = MockHumanoid(),
        HumanoidRootPart = MockPart(),
    }
end
