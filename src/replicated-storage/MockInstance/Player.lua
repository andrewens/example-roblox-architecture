-- public / MockPlayer methods
local function playerIsA(self, className)
	return className == "Player"
end

-- MockPlayer constructor
return function()
	return {
		Name = "MockPlayer",
		UserId = 0,

		IsA = playerIsA,
	}
end
