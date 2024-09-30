-- dependency
local PhysicsService = game:GetService("PhysicsService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local LOBBY_CHARACTER_COLLISION_GROUP = Config.getConstant("LobbyCharacterCollisionGroup")

-- var
local CharactersInLobby = {} -- Player --> Character

-- private
local function lobbyCharacterDespawned(Player)
	if CharactersInLobby[Player] == nil then
		return
	end

	CharactersInLobby[Player] = nil
	Network.fireAllClients("CharacterSpawnedInLobby", Player, nil)
end
local function lobbyCharacterSpawned(Player, Character)
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
local function spawnCharacterInLobby(Player)
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
local function initializePlayer(Player)
	-- TODO I think a client could invoke this twice, which would be bad
	Utility.onPlayerDiedConnect(Player, function()
		spawnCharacterInLobby(Player)
	end)

	spawnCharacterInLobby(Player)
end
local function disconnectPlayer(Player)
	lobbyCharacterDespawned(Player)
end
local function initializeLobbyCharacterServer()
	PhysicsService:RegisterCollisionGroup(LOBBY_CHARACTER_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(LOBBY_CHARACTER_COLLISION_GROUP, LOBBY_CHARACTER_COLLISION_GROUP, false)

	Network.onServerEventConnect("CharacterSpawnedInLobby", onPlayerRequestCharactersInLobby)
	Utility.onCharacterLoadedConnect(lobbyCharacterSpawned)
end

return {
	playerDataLoaded = initializePlayer,
	disconnectPlayer = disconnectPlayer,
	initialize = initializeLobbyCharacterServer,
}
