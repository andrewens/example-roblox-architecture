-- public / metamethods
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

-- public / MockPart class methods
local function isA(self, className)
	return className == "Part" or className == "BasePart"
end
local function destroy(self)

end

-- MockPart constructor
return function()
	local self = {
		-- properties
		Name = "Part",
		CFrame = CFrame.new(),
		Anchored = false,

		-- methods
		IsA = isA,
		Destroy = destroy,
	}

	setmetatable(self, MockPartMetatable)

	return self
end
