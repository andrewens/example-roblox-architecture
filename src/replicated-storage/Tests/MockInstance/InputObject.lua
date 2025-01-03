-- public / InputObject class methods
local function isA(self, className)
	return className == "InputObject"
end

-- Mock InputObject constructor
return function(Properties)
	Properties = Properties or {}

	if Properties.Delta then
		assert(typeof(Properties.Delta) == "Vector3")
	end
	if Properties.KeyCode then
		assert(typeof(Properties.KeyCode) == "EnumItem")
		if not (Properties.KeyCode.EnumType == Enum.KeyCode) then
			error(`{Properties.KeyCode.EnumType} is not Enum.KeyCode!`)
		end
	end
	if Properties.Position then
		assert(typeof(Properties.Position) == "Vector3")
	end
	if Properties.UserInputType then
		if not (typeof(Properties.UserInputType) == "EnumItem") then
			error(`{Properties.UserInputType} is not an EnumItem!`)
		end
		if not (Properties.UserInputType.EnumType == Enum.UserInputType) then
			error(`{Properties.UserInputType} is not a UserInputType Enum!`)
		end
	end
	if Properties.UserInputState then
		assert(typeof(Properties.UserInputState) == "EnumItem")
		assert(Properties.UserInputState.EnumType == Enum.UserInputState)
	end

	return {
		-- properties
		Name = "InputObject",
		Delta = Properties.Delta or Vector3.new(),
		KeyCode = Properties.KeyCode or Enum.KeyCode.A,
		Position = Properties.Position or Vector3.new(),
		UserInputState = Properties.UserInputState or Enum.UserInputState.Begin,
		UserInputType = Properties.UserInputType or Enum.UserInputType.Keyboard,

		-- methods
		IsA = isA,
	}
end
