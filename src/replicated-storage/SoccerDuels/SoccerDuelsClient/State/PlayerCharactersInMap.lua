-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Utility = require(SoccerDuelsModule.Utility)

local CharactersFolder
local PlaceholderCharacterRig

-- public / Client class methods
local function clonePlayerAvatar(self, Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local CharacterTemplate = CharactersFolder:FindFirstChild(Player.UserId)
	if CharacterTemplate == nil then
		warn(`{Player.Name} (UserId={Player.UserId}) has no cached character`)
		CharacterTemplate = PlaceholderCharacterRig
	end

	local ClonedCharacter = CharacterTemplate:Clone()
	ClonedCharacter.PrimaryPart = ClonedCharacter:FindFirstChild("HumanoidRootPart")
	ClonedCharacter.Name = Player.Name

	return ClonedCharacter
end
local function initializePlayerCharactersClientModule(self)
	CharactersFolder = Assets.getExpectedAsset("PlayerCharacterCacheFolder")
	PlaceholderCharacterRig = Assets.getExpectedAsset("PlayerCharacterPlaceholderRig")
end

return {
	clonePlayerAvatar = clonePlayerAvatar,

	initialize = initializePlayerCharactersClientModule,
}
