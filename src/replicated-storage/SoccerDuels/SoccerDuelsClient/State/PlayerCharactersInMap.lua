-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Utility = require(SoccerDuelsModule.Utility)

local CharactersFolder
local PlaceholderCharacterRig
local CharacterAnimationsFolder

-- public / Client class methods
local function clonePlayerAvatar(self, Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local CharacterTemplate = CharactersFolder:FindFirstChild(Player.UserId)
	if CharacterTemplate == nil then
		CharacterTemplate = PlaceholderCharacterRig
	end

	local ClonedCharacter = CharacterTemplate:Clone()
	ClonedCharacter.PrimaryPart = ClonedCharacter:FindFirstChild("HumanoidRootPart")
	ClonedCharacter.Name = Player.Name
	ClonedCharacter.Parent = workspace

	-- load animations onto humanoid
	local Animator = ClonedCharacter.Humanoid.Animator
	local AnimationTracks = {}

	for _, Animation in ipairs(CharacterAnimationsFolder:GetChildren()) do
		local AnimTrack = Animator:LoadAnimation(Animation)

		local priorityEnum
		local Priority = Animation:FindFirstChild("Priority")
		if Priority then
			priorityEnum = Enum.AnimationPriority[Priority.Value]
		else
			priorityEnum = Enum.AnimationPriority.Movement
		end

		AnimTrack.Priority = priorityEnum
		AnimationTracks[Animation.Name] = AnimTrack
	end

	local currAnim = nil
	local currSpeed = 1

	-- private
	local function playMovementAnimation(animName, animSpeed)
		animSpeed = animSpeed or 1
		if animName == currAnim and animSpeed == currSpeed then
			return
		end

		if animName == currAnim then -- we're just adjusting speed
			AnimationTracks[animName]:AdjustSpeed(animSpeed)
		else -- play a new animation
			if currAnim then
				AnimationTracks[currAnim]:Stop()
			end
			AnimationTracks[animName]:Play(0.2, 1, animSpeed)
		end

		currAnim = animName
		currSpeed = animSpeed
	end

	-- public
	local function setPrimaryPartCFrame(_, ...)
		ClonedCharacter:SetPrimaryPartCFrame(...)
	end
	local function destroy(_)
		ClonedCharacter:Destroy()
	end
	local function setHumanoidState(_, humanoidState)
		if humanoidState == Enum.HumanoidStateType.Running then
			playMovementAnimation("Run", 1)
		elseif humanoidState == Enum.HumanoidStateType.FallingDown or Enum.HumanoidStateType.Freefall then
			playMovementAnimation("Fall", 1)
		elseif humanoidState == Enum.HumanoidStateType.Jumping then
			playMovementAnimation("Jump", 1)
		else
			playMovementAnimation("Idle", 1)
		end
	end

	playMovementAnimation("Idle", 1)

	return {
		SetPrimaryPartCFrame = setPrimaryPartCFrame,
		SetHumanoidState = setHumanoidState,
		Destroy = destroy,
	}
end
local function initializePlayerCharactersClientModule(self)
	CharactersFolder = Assets.getExpectedAsset("PlayerCharacterCacheFolder")
	PlaceholderCharacterRig = Assets.getExpectedAsset("PlayerCharacterPlaceholderRig")
	CharacterAnimationsFolder = Assets.getExpectedAsset("PlayerCharacterAnimationsFolder")
end

return {
	clonePlayerAvatar = clonePlayerAvatar,

	initialize = initializePlayerCharactersClientModule,
}
