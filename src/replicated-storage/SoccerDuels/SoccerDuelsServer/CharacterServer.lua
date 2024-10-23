-- dependency
local PhysicsService = game:GetService("PhysicsService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)
local SoccerDuelsServer -- required in initialize()

local CharactersFolder

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local LOBBY_CHARACTER_COLLISION_GROUP = Config.getConstant("LobbyCharacterCollisionGroup")
local GOAL_CUTSCENE_DURATION = Config.getConstant("GoalCutsceneDurationSeconds")

-- var
local CharactersInLobby = {} -- Player --> Character

-- private
local function destroyCachedPlayerCharacter(Player)
	local Character = CharactersFolder:FindFirstChild(Player.UserId)
	if Character then
		Character:Destroy()
	end
end
local function cachePlayerCharacter(Player, Character)
	destroyCachedPlayerCharacter(Player)

	local ClonedCharacter = Utility.cloneCharacter(Character)
	ClonedCharacter.Name = Player.UserId
	ClonedCharacter.HumanoidRootPart.Anchored = true
	ClonedCharacter.Parent = CharactersFolder
end
local function lobbyCharacterDespawned(Player)
	if CharactersInLobby[Player] == nil then
		return
	end

	CharactersInLobby[Player] = nil
	Network.fireAllClients("CharacterSpawnedInLobby", Player, nil)
end
local function lobbyCharacterSpawned(Player, Character)
	if not SoccerDuelsServer.playerIsInLobby(Player) then
		return
	end

	CharactersInLobby[Player] = Character

	Character.Humanoid.Died:Connect(function()
		if CharactersInLobby[Player] ~= Character then
			return
		end
		lobbyCharacterDespawned(Player)
	end)

	for _, BasePart in Character:GetDescendants() do
		if not BasePart:IsA("BasePart") then
			continue
		end

		BasePart.CollisionGroup = LOBBY_CHARACTER_COLLISION_GROUP
	end

	Network.fireAllClients("CharacterSpawnedInLobby", Player, Character)
end
local function loadPlayerCharacter(Player)
	if not Utility.playerIsInGame(Player) then
		return
	end

	Player:LoadCharacter()

	-- TODO ideally there should be a mock Players service so that the connection is the same...
	if TESTING_MODE and typeof(Player) == "table" then
		lobbyCharacterSpawned(Player, Player.Character)
	end
end

-- protected / Network methods
local function onPlayerRequestCharactersInLobby(RequestingPlayer)
	for OtherPlayer, Character in CharactersInLobby do
		local Humanoid = Character:FindFirstChild("Humanoid")
		if Humanoid == nil or Humanoid.Health <= 0 then
			continue
		end

		Network.fireClient("CharacterSpawnedInLobby", RequestingPlayer, OtherPlayer, Character)
	end
end

-- public
local function removeCharacter(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if Player.Character then
		Player.Character:Destroy()
		Player.Character = nil
	end

	lobbyCharacterDespawned(Player)
end
local function spawnPlayerCharacterAtPosition(Player, position)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(position) == "Vector3") then
		error(`{position} is not a Vector3!`)
	end

	if Player.Character == nil or Player.Character.Parent == nil then
		loadPlayerCharacter(Player)
	end

	-- TODO this won't work with lag
	Player.Character:PivotTo(CFrame.new(position))
end
local function spawnCharacterInLobby(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	loadPlayerCharacter(Player)
end

local function disconnectPlayer(Player)
	lobbyCharacterDespawned(Player)
	task.delay(2 * GOAL_CUTSCENE_DURATION, destroyCachedPlayerCharacter, Player)
end
local function initializePlayer(Player)
	-- TODO I think a client could invoke this twice, which would be bad because the number of callbacks would duplicate
	Utility.onPlayerDiedConnect(Player, function()
		spawnCharacterInLobby(Player)
	end)

	spawnCharacterInLobby(Player)
end
local function initializeLobbyCharacterServer()
	SoccerDuelsServer = require(SoccerDuelsServerModule)

	CharactersFolder = Assets.getExpectedAsset("PlayerCharacterCacheFolder")
	Utility.onCharacterAppearanceLoadedConnect(cachePlayerCharacter)

	PhysicsService:RegisterCollisionGroup(LOBBY_CHARACTER_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(LOBBY_CHARACTER_COLLISION_GROUP, LOBBY_CHARACTER_COLLISION_GROUP, false)

	Network.onServerEventConnect("CharacterSpawnedInLobby", onPlayerRequestCharactersInLobby)
	Utility.onCharacterLoadedConnect(lobbyCharacterSpawned)
end

return {
	spawnPlayerCharacterAtPosition = spawnPlayerCharacterAtPosition,
	spawnPlayerCharacterInLobby = spawnCharacterInLobby,
	removePlayerCharacter = removeCharacter,

	initialize = initializeLobbyCharacterServer,
	disconnectPlayer = disconnectPlayer,
	playerDataLoaded = initializePlayer,
}
