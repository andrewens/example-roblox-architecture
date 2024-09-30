-- dependency
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local Event = require(MockInstanceModule.Event)

-- public / MockHumanoid class methods
local function isA(self, className)
    return className == "Humanoid"
end
local function humanoidTakeDamage(self, damage)
    self.Health -= damage

    if self.Health <= 0 then
        self.Parent = nil
        self.Died:Fire()
    end
end
local function destroyHumanoid(self)
    self.Parent = nil
end

-- MockHumanoid constructor
return function()
    return {
        -- properties
        Name = "Humanoid",
        Health = 100,
        MaxHealth = 100,
        Parent = nil,

        -- events
        Died = Event.new(),

        -- methods
        TakeDamage = humanoidTakeDamage,
        Destroy = destroyHumanoid,
        IsA = isA,
    }
end
