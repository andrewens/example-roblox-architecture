-- dependency
local RunService = game:GetService("RunService")

-- public / MockPlayer methods
local function kickPlayer(self, errorMessage)
	if not RunService:IsServer() then
		error(`{self.Name}:Kick() called on the Client`)
	end

	warn(`Kick {self.Name} with message: "{errorMessage}"`)
end
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
		Kick = kickPlayer,

		-- children
		PlayerGui = PlayerGuiFolder,
	}
end
