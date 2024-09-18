-- dependency
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local LOBBY_DEVICE_COLLISION_GROUP = Config.getConstant("LobbyDeviceCollisionGroup")
local LOBBY_DEVICE_TRANSPARENCY = Config.getConstant("LobbyDeviceTransparency")
local CHARACTER_TOUCH_SENSOR_SIZE = Config.getConstant("CharacterTouchSensorSizeVector3")
local CHARACTER_TOUCH_SENSOR_PART_NAME = Config.getConstant("CharacterTouchSensorPartName")
local MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME = Config.getConstant("MatchJoiningPadIdentifierAttributeName")
local TEAM1_COLOR = Config.getConstant("Team1Color")
local TEAM2_COLOR = Config.getConstant("Team2Color")

-- var
local MaxPlayersPerTeam = {} -- int matchPadEnum --> int

-- private
local function disconnectPlayerFromAllMatchPads(Player)
	Network.fireClient("PlayerJoinedMatchPad", Player, nil, nil)
end
local function initializeMatchJoinPad(Folder)
	local matchPadName = Folder.Name
	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		return
	end

	local maxPlayersPerTeam = tonumber(string.sub(matchPadName, 1, 1))

	local PadPart1 = Assets.getExpectedAsset(matchPadName .. " Pad1", matchPadName, Folder)
	local PadPart2 = Assets.getExpectedAsset(matchPadName .. " Pad2", matchPadName, Folder)

	PadPart1.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP
	PadPart2.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP

	PadPart1.Transparency = LOBBY_DEVICE_TRANSPARENCY
	PadPart2.Transparency = LOBBY_DEVICE_TRANSPARENCY

	PadPart1.Color = TEAM1_COLOR
	PadPart2.Color = TEAM2_COLOR

	PadPart1.CanCollide = false
	PadPart2.CanCollide = false

	PadPart1.CanQuery = false
	PadPart2.CanQuery = false

	PadPart1.CanTouch = true
	PadPart2.CanTouch = true

	PadPart1.Material = Enum.Material.Neon
	PadPart2.Material = Enum.Material.Neon

	PadPart1:SetAttribute(MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME, true)
	PadPart2:SetAttribute(MATCH_JOINING_PAD_IDENTIFIER_ATTRIBUTE_NAME, true)

	MaxPlayersPerTeam[matchPadEnum] = maxPlayersPerTeam
end

-- protected / Network methods
local connectPlayerToMatchPad
local function clientJoinMatchPad(Player, matchPadEnum, teamIndex)
	if Player.Character == nil or Player.Character.Parent == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	if matchPadEnum == nil then
		disconnectPlayerFromAllMatchPads(Player)
		return
	end

	local matchPadName = Enums.enumToName("MatchJoiningPad", matchPadEnum)
	if matchPadName == nil then
		error(`{matchPadEnum} is not a match pad enum!`)
	end

	connectPlayerToMatchPad(Player, matchPadName, teamIndex)
end

-- public
local function playerCharacterLoaded(Player, Character)
	local TouchSensorPart = Instance.new("Part")
	TouchSensorPart.CollisionGroup = LOBBY_DEVICE_COLLISION_GROUP
	TouchSensorPart.Transparency = LOBBY_DEVICE_TRANSPARENCY
	TouchSensorPart.Size = CHARACTER_TOUCH_SENSOR_SIZE
	TouchSensorPart.Name = CHARACTER_TOUCH_SENSOR_PART_NAME
	TouchSensorPart.Color = Color3.new(1, 0, 1)
	TouchSensorPart.Material = Enum.Material.Neon
	TouchSensorPart.CanCollide = false
	TouchSensorPart.CanQuery = false
	TouchSensorPart.CanTouch = true

	Utility.weldPartToPart(TouchSensorPart, Character.HumanoidRootPart)

	TouchSensorPart.Parent = Character
end
local function disconnectPlayer(Player)
	disconnectPlayerFromAllMatchPads(Player)
end
function connectPlayerToMatchPad(Player, matchPadName, teamIndex)
	-- TODO return if player is disconnected from SoccerDuelsServer

	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(matchPadName) == "string") then
		error(`{matchPadName} is not a string!`)
	end
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	local matchPadEnum = Enums.getEnum("MatchJoiningPad", matchPadName)
	if matchPadEnum == nil then
		error(`{matchPadName} is not the name of a match joining pad!`)
	end

	Network.fireClient("PlayerJoinedMatchPad", Player, matchPadEnum, teamIndex)
end
local function getMatchJoiningPads()
	local Pads = {}

	for matchPadEnum, maxPlayersPerTeam in MaxPlayersPerTeam do
		Pads[matchPadEnum] = {
			Name = Enums.enumToName("MatchJoiningPad", matchPadEnum),
			MaxPlayersPerTeam = maxPlayersPerTeam,
			Team1 = {},
			Team2 = {},
		}
	end

	return Pads
end
local function initializeMatchJoiningPads()
	local MatchJoiningPadsFolder = Assets.getExpectedAsset("MatchJoiningPadsFolder")
	for _, Folder in MatchJoiningPadsFolder:GetChildren() do
		initializeMatchJoinPad(Folder)
	end

	Network.onServerInvokeConnect("PlayerJoinMatchPad", clientJoinMatchPad)

	PhysicsService:RegisterCollisionGroup(LOBBY_DEVICE_COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(LOBBY_DEVICE_COLLISION_GROUP, "Default", false)

	-- workspace.TouchesUseCollisionGroups needs to be set to true

	Utility.onCharacterLoadedConnect(playerCharacterLoaded)
end

return {
	playerCharacterLoaded = playerCharacterLoaded,
	disconnectPlayer = disconnectPlayer,
	connectPlayerToMatchPad = connectPlayerToMatchPad,
	getMatchJoiningPads = getMatchJoiningPads,
	initialize = initializeMatchJoiningPads,
}
