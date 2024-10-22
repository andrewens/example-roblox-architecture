-- dependency
local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local Event = require(MockInstanceModule.Event)

-- public / MockHumanoid class methods
local newMockHumanoid
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
local function cloneHumanoid(self)
    return newMockHumanoid(self)
end
local function destroyHumanoid(self)
	self.Parent = nil
end
function newMockHumanoid(InputData)
    InputData = InputData or {}

	return {
		-- properties
		Name = InputData.Name or "Humanoid",
		Health = InputData.Health or 100,
		MaxHealth = InputData.MaxHealth or 100,
		Parent = InputData.Parent, -- or nil

		-- events
		Died = Event.new(),

		-- methods
		TakeDamage = humanoidTakeDamage,
		Destroy = destroyHumanoid,
        Clone = cloneHumanoid,
		IsA = isA,
	}
end

-- MockHumanoid constructor
return newMockHumanoid
