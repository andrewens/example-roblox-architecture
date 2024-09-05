-- dependency
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local MockHumanoid = require(MockInstanceModule.Humanoid)

-- public / MockCharacter class methods
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

        -- children
        Humanoid = MockHumanoid(),
    }
end
