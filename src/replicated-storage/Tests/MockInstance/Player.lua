-- dependency
local RunService = game:GetService("RunService")

local MockInstanceModule = script:FindFirstAncestor("MockInstance")

local Event = require(MockInstanceModule.Event)
local MockCharacter = require(MockInstanceModule.Character)

-- public / MockPlayer class methods
local function playerLoadCharacter(self)
	if self.Character then
		self.Character:Destroy()
	end

	self.Character = MockCharacter()
	self.Character.Name = self.Name
	self.Character.Parent = workspace

	self.CharacterAdded:Fire(self.Character)
end
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
		Character = nil,

		-- methods
		IsA = playerIsA,
		Kick = kickPlayer,
		LoadCharacter = playerLoadCharacter,

		-- events
		CharacterAdded = Event.new(),

		-- children
		PlayerGui = PlayerGuiFolder,
	}
end
