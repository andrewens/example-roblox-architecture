-- public / MockPlayer methods
local function playerIsA(self, className)
	return className == "Player"
end

-- MockPlayer constructor
return function()
	local PlayerGuiFolder = Instance.new("Folder")
	PlayerGuiFolder.Name = "PlayerGui"

	return {
		-- properties
		Name = "MockPlayer",
		UserId = 0,

		-- methods
		IsA = playerIsA,

		-- children
		PlayerGui = PlayerGuiFolder,
	}
end
