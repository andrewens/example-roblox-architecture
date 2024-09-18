local function indexMockPart(self, key)
	if key == "Position" then
		return self.CFrame.Position
	end
end
local function newindexMockPart(self, key, value)
	if key == "Position" then
		self.CFrame = CFrame.new(value) -- TODO I think Parts preserve the orientation if you do this, so might have to do that in the future
	end
end

local MockPartMetatable = {
	__index = indexMockPart,
	__newindex = newindexMockPart,
}

-- MockPart constructor
return function()
	local self = {}
	self.Name = "Part"
	self.CFrame = CFrame.new()

	setmetatable(self, MockPartMetatable)

	return self
end
