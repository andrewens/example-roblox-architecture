-- dependency
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local MATCH_JOINING_PAD_RADIUS_PADDING_STUDS = Config.getConstant("MatchJoiningPadRadiusPaddingStuds")
local PLAYER_STEPPED_OFF_PADS_CHECK_RATE_SECONDS =
	Config.getConstant("SecondsBetweenCheckingIfPlayersSteppedOffMatchJoiningPads")

-- var
local MaxPlayersPerTeam = {} -- int matchPadEnum --> int
local PlayerToPadPart = {} -- Player -->

-- private
local function playerIsStandingOnPadPart(Player, MatchPadPart)
	local Character = Player.Character
	if Character == nil or Character.Parent == nil then
		return false
	end

	local matchPadRadius = 0.5 * MatchPadPart.Size.X
	local charPosition = Character:GetPivot().Position
	local offset = charPosition - MatchPadPart.Position

	return offset:Dot(offset) <= (matchPadRadius + MATCH_JOINING_PAD_RADIUS_PADDING_STUDS) ^ 2
end
local function disconnectPlayerFromAllMatchPads(Player)
	Network.fireClient("PlayerJoinedMatchPad", Player, nil, nil)
	PlayerToPadPart[Player] = nil
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

	PadPart1.CanCollide = false
	PadPart2.CanCollide = false

	PadPart1.Transparency = 1
	PadPart2.Transparency = 1

	MaxPlayersPerTeam[matchPadEnum] = maxPlayersPerTeam
end

-- protected / Network methods
local function clientJoinMatchPad(Player, matchPadEnum, teamIndex)
	-- TODO return if player is disconnected from SoccerDuelsServer
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
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	-- teleport character to pad if they're not already on it
	local MatchPadPart = Assets.getExpectedAsset(`{matchPadName} Pad{teamIndex}`)
	if not playerIsStandingOnPadPart(Player, MatchPadPart) then
		Player.Character:MoveTo(MatchPadPart.Position + Vector3.new(0, 3, 0))
	end

	PlayerToPadPart[Player] = MatchPadPart
	Network.fireClient("PlayerJoinedMatchPad", Player, matchPadEnum, teamIndex)
end

-- public
local function disconnectPlayersFromMatchJoiningPadsIfTheySteppedOff()
	for Player, PadPart in PlayerToPadPart do
		if not playerIsStandingOnPadPart(Player, PadPart) then
			disconnectPlayerFromAllMatchPads(Player)
		end
	end
end
local function disconnectPlayer(Player)
	Network.fireClient("PlayerJoinedMatchPad", Player, nil, nil)
end
local function connectPlayerToMatchPad(Player, matchPadName, teamIndex)
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

	Utility.runServiceSteppedConnect(
		PLAYER_STEPPED_OFF_PADS_CHECK_RATE_SECONDS,
		disconnectPlayersFromMatchJoiningPadsIfTheySteppedOff
	)
end

return {
	disconnectPlayersFromMatchJoiningPadsIfTheySteppedOff = disconnectPlayersFromMatchJoiningPadsIfTheySteppedOff,
	disconnectPlayer = disconnectPlayer,
	connectPlayerToMatchPad = connectPlayerToMatchPad,
	getMatchJoiningPads = getMatchJoiningPads,
	initialize = initializeMatchJoiningPads,
}
