-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsServerModule = script:FindFirstAncestor("SoccerDuelsServer")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Network = require(SoccerDuelsModule.Network)
local Time = require(SoccerDuelsModule.Time)
local Utility = require(SoccerDuelsModule.Utility)

local SoccerDuelsServer -- required in initialize()
local SoccerBallServer -- required in initialize()
local CharacterServer = require(SoccerDuelsServerModule.CharacterServer)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

local MAX_NUM_MAP_INSTANCES_PER_GRID_ROW = Config.getConstant("MaxMapInstancesPerGridRow")
local STUDS_BETWEEN_MAP_INSTANCES = Config.getConstant("DistanceBetweenMapInstancesStuds")

local MAP_STATE_TICK_RATE_SECONDS = Config.getConstant("MapStateTickRateSeconds")
local NUMBER_OF_MATCHES_PER_GAME = Config.getConstant("NumberOfMatchesPerGame")
local MAX_PLAYERS_PER_TEAM = Config.getConstant("MaxPlayersPerTeam")

local MAP_LOADING_DURATION_SECONDS = Config.getConstant("MapLoadingDurationSeconds")
local MATCH_COUNTDOWN_DURATION_SECONDS = Config.getConstant("MatchCountdownDurationSeconds")
local MATCH_GAMEPLAY_DURATION_SECONDS = Config.getConstant("MatchGameplayDurationSeconds")
local MATCH_OVER_DURATION_SECONDS = Config.getConstant("MatchOverDurationSeconds")
local GOAL_CUTSCENE_DURATION_SECONDS = Config.getConstant("GoalCutsceneDurationSeconds")
local GAME_OVER_DURATION_SECONDS = Config.getConstant("GameOverDurationSeconds")

local MAP_LOADING_STATE_ENUM = Enums.getEnum("MapState", "Loading")
local MATCH_COUNTDOWN_STATE_ENUM = Enums.getEnum("MapState", "MatchCountdown")
local MATCH_GAMEPLAY_STATE_ENUM = Enums.getEnum("MapState", "MatchGameplay")
local MATCH_OVER_STATE_ENUM = Enums.getEnum("MapState", "MatchOver")
local GOAL_CUTSCENE_STATE_ENUM = Enums.getEnum("MapState", "GoalCutscene")
local GAME_OVER_STATE_ENUM = Enums.getEnum("MapState", "GameOver")
local PERPETUAL_GAMEPLAY_STATE_ENUM = Enums.getEnum("MapState", "Gameplay")

local DEFAULT_MATCH_CYCLE_ENABLED = Config.getConstant("DefaultMapInstanceOptions", "MatchCycleEnabled")

-- var
local mapGridOrigin -- Vector3
local mapInstanceCounter = 0 -- int
local MapInstanceIdToMapPositionIndex = {} -- int mapInstanceId --> int mapPositionIndex
local MapInstanceFolder = {} -- int mapPositionIndex --> Folder
local MapInstancePlayers = {} -- int mapInstanceId --> { Player --> int teamIndex ( 1 or 2 ) }
local PlayerConnectedMapInstance = {} -- Player --> mapInstanceId

local MapInstanceState = {} -- int mapInstanceId --> int mapStateEnum
local MapInstanceStateChangeTimestamp = {} -- int mapInstanceId --> int unixTimestampMilliseconds
local MapInstanceMatchesPlayed = {} -- int mapInstanceId --> int numberOfMatchesPlayed
local MapInstanceMapEnum = {} -- int mapInstanceId --> int mapEnum
local MapInstanceScore = {} -- int mapInstanceId --> int teamIndex --> int numGoalsScored
local PlayerThatScoredLastGoal = {} -- int mapInstanceId --> Player | nil

local PlayerGoals = {} -- Player --> int | nil numGoals
local PlayerAssists = {} -- Player --> int | nil numAssists
local PlayerTackles = {} -- Player --> int | nil numTackles

-- private
local function wipeClientCopyOfMatchScore(Player)
	Network.fireClient("MatchScoreChanged", Player, nil)
end
local function resetMapInstanceScore(mapInstanceId)
	MapInstanceScore[mapInstanceId] = { 0, 0 }

	for Player, otherTeamIndex in MapInstancePlayers[mapInstanceId] do
		Network.fireClient("MatchScoreChanged", Player, 0, 0)
	end
end
local function incrementMapInstanceScore(mapInstanceId, teamIndex)
	MapInstanceScore[mapInstanceId][teamIndex] += 1

	for Player, otherTeamIndex in MapInstancePlayers[mapInstanceId] do
		Network.fireClient("MatchScoreChanged", Player, table.unpack(MapInstanceScore[mapInstanceId]))
	end
end
local function replicateMapInstanceScoreToPlayer(Player, mapInstanceId)
	Network.fireClient("MatchScoreChanged", Player, table.unpack(MapInstanceScore[mapInstanceId]))
end

local function addPlayerToLeaderstats(Player, mapInstanceId, teamIndex)
	PlayerGoals[Player] = 0
	PlayerAssists[Player] = 0
	PlayerTackles[Player] = 0

	for OtherPlayer, otherTeamIndex in MapInstancePlayers[mapInstanceId] do
		-- replicate new player's stats to the other players
		Network.fireClient("PlayerLeaderstatsChanged", OtherPlayer, Player, teamIndex, 0, 0, 0)

		-- replicate other players' stats to this new player
		if OtherPlayer == Player then
			continue
		end

		local goals = PlayerGoals[OtherPlayer]
		local assists = PlayerAssists[OtherPlayer]
		local tackles = PlayerTackles[OtherPlayer]

		Network.fireClient("PlayerLeaderstatsChanged", Player, OtherPlayer, otherTeamIndex, goals, assists, tackles)
	end
end
local function replicatePlayerLeaderstats(Player)
	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	local goals = PlayerGoals[Player]
	local assists = PlayerAssists[Player]
	local tackles = PlayerTackles[Player]
	local teamIndex = if goals then MapInstancePlayers[mapInstanceId][Player] else nil

	for OtherPlayer, otherTeamIndex in MapInstancePlayers[mapInstanceId] do
		Network.fireClient("PlayerLeaderstatsChanged", OtherPlayer, Player, teamIndex, goals, assists, tackles)
	end
end
local function incrementPlayerLeaderstats(Player, newGoals, newAssists, newTackles)
	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	if newGoals and newGoals > 0 then
		PlayerGoals[Player] += newGoals
	end
	if newAssists and newAssists > 0 then
		PlayerAssists[Player] += newAssists
	end
	if newTackles and newTackles > 0 then
		PlayerTackles[Player] += newTackles
	end

	replicatePlayerLeaderstats(Player)
end
local function deletePlayerLeaderstats(Player)
	PlayerGoals[Player] = nil
	PlayerAssists[Player] = nil
	PlayerTackles[Player] = nil

	replicatePlayerLeaderstats(Player)
end

local function replicateMapStateToPlayer(Player)
	local mapStateEnum, stateEndTimestamp

	local connectedMapId = PlayerConnectedMapInstance[Player]
	if connectedMapId then
		mapStateEnum = MapInstanceState[connectedMapId]
		stateEndTimestamp = MapInstanceStateChangeTimestamp[connectedMapId]
	end

	Network.fireClient("MapStateChanged", Player, mapStateEnum, stateEndTimestamp)
end
local function getMapInstanceStartingLocationUnprotected(mapInstanceId, teamIndex, teamPositionIndex)
	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	local MapFolder = MapInstanceFolder[mapPositionIndex]
	local mapName = Enums.enumToName("Map", MapInstanceMapEnum[mapInstanceId])
	local StartPositionPart = Assets.getExpectedAsset(
		`{mapName} Team{teamIndex} StartPosition{teamPositionIndex}`,
		`{mapName} MapFolder`,
		MapFolder
	)

	return StartPositionPart.Position + Vector3.new(0, 3, 0)
end

local destroyMapInstance, getMapInstanceWinningTeam
local function setMapState(mapInstanceId, mapStateEnum, durationSeconds)
	-- store and replicate new map state
	local stateChangeTimestamp
	if durationSeconds then
		stateChangeTimestamp = Time.getUnixTimestampMilliseconds() + 1E3 * durationSeconds
	end

	MapInstanceState[mapInstanceId] = mapStateEnum
	MapInstanceStateChangeTimestamp[mapInstanceId] = stateChangeTimestamp

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		replicateMapStateToPlayer(Player)
	end

	-- 'MatchCountdown' - spawn characters at their starting positions (and freeze them) + reset PlayerThatScoredLastGoal
	if mapStateEnum == MATCH_COUNTDOWN_STATE_ENUM then
		-- no one scored the last goal
		PlayerThatScoredLastGoal[mapInstanceId] = nil

		local TeamPositionIndex = { 0, 0 } -- int teamIndex --> int teamPositionIndex
		for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
			-- move their character to a starting position
			TeamPositionIndex[teamIndex] += 1
			local startingPosition =
				getMapInstanceStartingLocationUnprotected(mapInstanceId, teamIndex, TeamPositionIndex[teamIndex])

			CharacterServer.spawnPlayerCharacterAtPosition(Player, startingPosition)
			Utility.setPlayerCharacterAnchored(Player, true)
		end

		return
	end

	-- 'MatchGameplay' - unfreeze player characters | spawn soccer ball
	if mapStateEnum == MATCH_GAMEPLAY_STATE_ENUM then
		SoccerBallServer.newSoccerBall(mapInstanceId)

		for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
			Utility.setPlayerCharacterAnchored(Player, false)
		end

		return
	end

	-- 'Loading' | 'GoalCutscene' | 'GameOver' - remove player characters / save wins & losses in `GameOver`
	if
		mapStateEnum == MAP_LOADING_STATE_ENUM
		or mapStateEnum == GOAL_CUTSCENE_STATE_ENUM
		or mapStateEnum == GAME_OVER_STATE_ENUM
	then
		-- 'GameOver' save wins and losses
		if mapStateEnum == GAME_OVER_STATE_ENUM then
			local winningTeamIndex = getMapInstanceWinningTeam(mapInstanceId)

			for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
				if teamIndex == winningTeamIndex then
					SoccerDuelsServer.incrementCachedPlayerSaveData(Player, {
						Wins = 1,
						WinStreak = 1,
					})

					continue
				end

				SoccerDuelsServer.incrementCachedPlayerSaveData(Player, {
					Losses = 1,
				})
			end
		end

		-- remove characters
		for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
			CharacterServer.removePlayerCharacter(Player)
		end

		return
	end

	-- 'Gameplay' - spawn characters
	if mapStateEnum == PERPETUAL_GAMEPLAY_STATE_ENUM then
		for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
			-- move their character to a starting position
			local startingPosition = getMapInstanceStartingLocationUnprotected(mapInstanceId, teamIndex, 1)

			CharacterServer.spawnPlayerCharacterAtPosition(Player, startingPosition)
		end
	end
end
local function mapInstanceHasNoPlayersOnATeam(mapInstanceId)
	local team1HasPlayers = false
	local team2HasPlayers = false

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		if teamIndex == 1 then
			team1HasPlayers = true
		else
			team2HasPlayers = true
		end

		if team1HasPlayers and team2HasPlayers then
			return false
		end
	end

	return not (team1HasPlayers and team2HasPlayers)
end
local function updateMapStateAfterPlayerScoredGoal(mapInstanceId, Player)
	if not (MapInstanceState[mapInstanceId] == MATCH_GAMEPLAY_STATE_ENUM) then
		return
	end

	setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
	PlayerThatScoredLastGoal[mapInstanceId] = Player
end
local function updateMapStateAfterPlayerLeft(mapInstanceId)
	-- if MatchCycleEnabled=false, we don't do anything
	if MapInstanceMatchesPlayed[mapInstanceId] == nil then
		return
	end

	-- 'MatchGameplay' --> 'MatchOver' when there are no players on a team
	local currentStateEnum = MapInstanceState[mapInstanceId]
	if currentStateEnum == MATCH_GAMEPLAY_STATE_ENUM then
		if not mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			return
		end

		setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
		return
	end
end
local function updateMapState(mapInstanceId)
	local currentStateEnum = MapInstanceState[mapInstanceId]
	local stateChangeTimestamp = MapInstanceStateChangeTimestamp[mapInstanceId]

	if stateChangeTimestamp == nil then
		return
	end

	local now = Time.getUnixTimestampMilliseconds()
	if now < stateChangeTimestamp then
		return
	end

	-- 'Loading' --> 'MatchCountdown' | 'Gameplay' (dependencing on MatchCycleEnabled)
	if currentStateEnum == MAP_LOADING_STATE_ENUM then
		-- MatchCycleEnabled=true
		if MapInstanceMatchesPlayed[mapInstanceId] then -- (interpret having a number of matches played as MatchCycleEnabled=true)
			setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
			return
		end

		-- MatchCycleEnabled=false
		setMapState(mapInstanceId, PERPETUAL_GAMEPLAY_STATE_ENUM, nil)
		return
	end

	-- 'MatchCountdown' --> 'MatchGameplay' | 'MatchOver' (if a team has no players on it)
	if currentStateEnum == MATCH_COUNTDOWN_STATE_ENUM then
		if mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
			return
		end

		setMapState(mapInstanceId, MATCH_GAMEPLAY_STATE_ENUM, MATCH_GAMEPLAY_DURATION_SECONDS)
		return
	end

	-- 'MatchGameplay' --> 'MatchOver'
	if currentStateEnum == MATCH_GAMEPLAY_STATE_ENUM then
		setMapState(mapInstanceId, MATCH_OVER_STATE_ENUM, MATCH_OVER_DURATION_SECONDS)
		return
	end

	-- 'MatchOver' --> 'GoalCutscene' | 'MatchCountdown' | 'GameOver'
	if currentStateEnum == MATCH_OVER_DURATION_SECONDS then
		-- go to 'GoalCutscene' if someone scored a goal
		if PlayerThatScoredLastGoal[mapInstanceId] then
			setMapState(mapInstanceId, GOAL_CUTSCENE_STATE_ENUM, GOAL_CUTSCENE_DURATION_SECONDS)
			return
		end

		-- go to 'GameOver' if we've played all of the matches
		MapInstanceMatchesPlayed[mapInstanceId] += 1
		if MapInstanceMatchesPlayed[mapInstanceId] >= NUMBER_OF_MATCHES_PER_GAME then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'GameOver' if a team has no players on it
		if mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'MatchCountdown' to repeat the loop otherwise
		setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
		return
	end

	-- 'GoalCutscene' --> 'MatchCountdown' | 'GameOver'
	if currentStateEnum == GOAL_CUTSCENE_STATE_ENUM then
		-- go to 'GameOver' if we've played all of the matches
		MapInstanceMatchesPlayed[mapInstanceId] += 1
		if MapInstanceMatchesPlayed[mapInstanceId] >= NUMBER_OF_MATCHES_PER_GAME then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'GameOver' if a team has no players on it
		if mapInstanceHasNoPlayersOnATeam(mapInstanceId) then
			setMapState(mapInstanceId, GAME_OVER_STATE_ENUM, GAME_OVER_DURATION_SECONDS)
			return
		end

		-- go to 'MatchCountdown' to repeat the loop otherwise
		setMapState(mapInstanceId, MATCH_COUNTDOWN_STATE_ENUM, MATCH_COUNTDOWN_DURATION_SECONDS)
		return
	end

	-- 'GameOver' --> nil (destroy the map)
	if currentStateEnum == GAME_OVER_STATE_ENUM then
		destroyMapInstance(mapInstanceId)
		return
	end
end

local function getNewMapId()
	mapInstanceCounter += 1
	return mapInstanceCounter
end
local function getUnusedMapPositionIndex()
	local mapPositionIndex = 0
	repeat
		mapPositionIndex += 1
	until MapInstanceFolder[mapPositionIndex] == nil

	return mapPositionIndex
end
local function mapPositionIndexToOriginPosition(mapPositionIndex)
	return mapGridOrigin
		+ Vector3.new(
				((mapPositionIndex - 1) % MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5,
				0,
				math.floor(mapPositionIndex / MAX_NUM_MAP_INSTANCES_PER_GRID_ROW) + 0.5
			)
			* STUDS_BETWEEN_MAP_INSTANCES
end

-- public
local function playerTackledAnotherPlayer(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	local mapStateEnum = MapInstanceState[mapInstanceId]
	if not (mapStateEnum == MATCH_GAMEPLAY_STATE_ENUM or mapStateEnum == PERPETUAL_GAMEPLAY_STATE_ENUM) then
		return
	end

	incrementPlayerLeaderstats(Player, 0, 0, 1)
	SoccerDuelsServer.incrementCachedPlayerSaveData(Player, { Tackles = 1 })
end
local function playerAssistedGoal(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	local mapStateEnum = MapInstanceState[mapInstanceId]
	if not (mapStateEnum == MATCH_GAMEPLAY_STATE_ENUM or mapStateEnum == PERPETUAL_GAMEPLAY_STATE_ENUM) then
		return
	end

	incrementPlayerLeaderstats(Player, 0, 1, 0)
	SoccerDuelsServer.incrementCachedPlayerSaveData(Player, { Assists = 1 })
end
local function playerScoredGoal(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	local mapStateEnum = MapInstanceState[mapInstanceId]
	if not (mapStateEnum == MATCH_GAMEPLAY_STATE_ENUM or mapStateEnum == PERPETUAL_GAMEPLAY_STATE_ENUM) then
		return
	end

	local teamIndex = MapInstancePlayers[mapInstanceId][Player]

	incrementMapInstanceScore(mapInstanceId, teamIndex)
	incrementPlayerLeaderstats(Player, 1, 0, 0)
	updateMapStateAfterPlayerScoredGoal(mapInstanceId, Player)

	SoccerDuelsServer.incrementCachedPlayerSaveData(Player, { Goals = 1 })
end

local function getMapInstanceStartingLocation(mapInstanceId, teamIndex, teamPositionIndex)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not an integer!`)
	end
	if MapInstanceIdToMapPositionIndex[mapInstanceId] == nil then
		error(`Map {mapInstanceId} doesn't exist!`)
	end
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end
	if not (Utility.isInteger(teamPositionIndex)) then
		error(`{teamPositionIndex} is not an integer!`)
	end
	if not (1 <= teamPositionIndex and teamPositionIndex <= MAX_PLAYERS_PER_TEAM) then
		error(`{teamPositionIndex} is out of range!`)
	end

	return getMapInstanceStartingLocationUnprotected(mapInstanceId, teamIndex, teamPositionIndex)
end
local function getMapInstanceState(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapStateEnum = MapInstanceState[mapInstanceId]
	if mapStateEnum == nil then
		return nil
	end

	return Enums.enumToName("MapState", mapStateEnum)
end
local function getPlayerTeamIndex(Player) -- TODO will probably want to make this work with match joining pads as well
	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	return MapInstancePlayers[mapInstanceId][Player]
end
local function mapTimerTick()
	for mapInstanceId, _ in MapInstanceStateChangeTimestamp do
		updateMapState(mapInstanceId)
	end
end

local function disconnectPlayerFromAllMapInstances(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local mapInstanceId = PlayerConnectedMapInstance[Player]
	if mapInstanceId == nil then
		return
	end

	wipeClientCopyOfMatchScore(Player)
	deletePlayerLeaderstats(Player) --> must happen before the player's connected map instance & teamIndex are nil

	MapInstancePlayers[mapInstanceId][Player] = nil
	PlayerConnectedMapInstance[Player] = nil

	Network.fireAllClients("PlayerConnectedMapChanged", Player, nil, nil, nil)

	updateMapStateAfterPlayerLeft(mapInstanceId)
	replicateMapStateToPlayer(Player)

	CharacterServer.spawnPlayerCharacterInLobby(Player)
end
local function getPlayersConnectedToMapInstance(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return MapInstancePlayers[mapInstanceId]
end
local function getPlayerConnectedMapInstance(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	return PlayerConnectedMapInstance[Player]
end
local function connectPlayerToMapInstance(Player, mapInstanceId, teamIndex)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		error(`{Player.Name}'s data is not loaded!`)
	end
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not an integer!`)
	end
	if not (teamIndex == 1 or teamIndex == 2) then
		error(`{teamIndex} is not 1 or 2!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		error(`{mapInstanceId} is not an active map instance id!`)
	end

	local MapFolder = MapInstanceFolder[mapPositionIndex]
	if MapFolder == nil then
		error(`Map {mapInstanceId} has no Folder!`)
	end

	disconnectPlayerFromAllMapInstances(Player)

	MapInstancePlayers[mapInstanceId][Player] = teamIndex
	PlayerConnectedMapInstance[Player] = mapInstanceId

	replicateMapStateToPlayer(Player)
	addPlayerToLeaderstats(Player, mapInstanceId, teamIndex)
	replicateMapInstanceScoreToPlayer(Player, mapInstanceId)

	Network.fireAllClients("PlayerConnectedMapChanged", Player, MapInstanceMapEnum[mapInstanceId], teamIndex, MapFolder)

	CharacterServer.removePlayerCharacter(Player)

	-- spawn characters into practice fields
	if MapInstanceState[mapInstanceId] == PERPETUAL_GAMEPLAY_STATE_ENUM then
		local startingPosition = getMapInstanceStartingLocationUnprotected(mapInstanceId, teamIndex, 1)
		CharacterServer.spawnPlayerCharacterAtPosition(Player, startingPosition)
	end
end
local function playerIsInLobby(Player)
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if not SoccerDuelsServer.playerDataIsLoaded(Player) then
		return false
	end

	return PlayerConnectedMapInstance[Player] == nil
end

function getMapInstanceWinningTeam(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	if MapInstanceScore[mapInstanceId] == nil then
		return
	end

	local team1Score, team2Score = table.unpack(MapInstanceScore[mapInstanceId])
	if team1Score == team2Score then
		return nil
	end

	return if team1Score > team2Score then 1 else 2
end
local function getPlayerThatScoredLastGoal(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return PlayerThatScoredLastGoal[mapInstanceId]
end
local function getMapInstanceMapName(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	return Enums.enumToName("Map", MapInstanceMapEnum[mapInstanceId])
end
local function getMapInstanceFolder(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return nil
	end

	return MapInstanceFolder[mapPositionIndex]
end
local function getMapInstanceOrigin(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return nil
	end

	return mapPositionIndexToOriginPosition(mapPositionIndex)
end
local function getMapInstanceScore(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return nil
	end

	return table.unpack(MapInstanceScore[mapInstanceId])
end
function destroyMapInstance(mapInstanceId)
	if not Utility.isInteger(mapInstanceId) then
		error(`{mapInstanceId} is not a map instance id!`)
	end

	local mapPositionIndex = MapInstanceIdToMapPositionIndex[mapInstanceId]
	if mapPositionIndex == nil then
		return
	end

	local MapFolder = MapInstanceFolder[mapPositionIndex]
	if MapFolder == nil then
		return
	end

	for Player, teamIndex in MapInstancePlayers[mapInstanceId] do
		disconnectPlayerFromAllMapInstances(Player)
	end

	MapFolder:Destroy()
	MapInstanceFolder[mapPositionIndex] = nil

	MapInstancePlayers[mapInstanceId] = nil
	MapInstanceIdToMapPositionIndex[mapInstanceId] = nil

	MapInstanceState[mapInstanceId] = nil
	MapInstanceStateChangeTimestamp[mapInstanceId] = nil
	MapInstanceMatchesPlayed[mapInstanceId] = nil
	MapInstanceScore[mapInstanceId] = nil
	PlayerThatScoredLastGoal[mapInstanceId] = nil
end
local function newMapInstance(mapName, Options)
	Options = Options or {}
	local mapEnum = Enums.getEnum("Map", mapName)

	if not (typeof(mapName) == "string") then
		error(`{mapName} is not a string!`)
	end
	if mapEnum == nil then
		error(`{mapName} is not a Map!`)
	end
	if not (typeof(Options) == "table") then
		error(`{Options} is not a table!`)
	end

	local MATCH_CYCLE_ENABLED = if Options.MatchCycleEnabled ~= nil
		then Options.MatchCycleEnabled
		else DEFAULT_MATCH_CYCLE_ENABLED

	if not (typeof(MATCH_CYCLE_ENABLED) == typeof(DEFAULT_MATCH_CYCLE_ENABLED)) then
		error(`{MATCH_CYCLE_ENABLED} is not a {typeof(DEFAULT_MATCH_CYCLE_ENABLED)}!`)
	end

	local mapInstanceId = getNewMapId() -- the mapInstanceId must never be reused so we can reliably check if a map instance has been destroyed
	local mapPositionIndex = getUnusedMapPositionIndex() -- but we can reuse the position placement of the map
	local mapOrigin = mapPositionIndexToOriginPosition(mapPositionIndex)

	local mapFolderAssetName = `{mapName} MapFolder`
	local mapOriginPartAssetName = `{mapName} MapOriginPart`

	local MapFolder = Assets.cloneExpectedAsset(mapFolderAssetName)
	local MapOriginPart = Assets.getExpectedAsset(mapOriginPartAssetName, mapFolderAssetName, MapFolder)

	MapFolder.PrimaryPart = MapOriginPart
	MapFolder:PivotTo(CFrame.new(mapOrigin))
	MapFolder.Parent = workspace

	MapInstanceFolder[mapPositionIndex] = MapFolder
	MapInstancePlayers[mapInstanceId] = {}
	MapInstanceIdToMapPositionIndex[mapInstanceId] = mapPositionIndex
	MapInstanceMapEnum[mapInstanceId] = mapEnum

	if MATCH_CYCLE_ENABLED then
		MapInstanceMatchesPlayed[mapInstanceId] = 0
	end

	resetMapInstanceScore(mapInstanceId)
	setMapState(mapInstanceId, MAP_LOADING_STATE_ENUM, MAP_LOADING_DURATION_SECONDS)

	return mapInstanceId
end

local function getAllMapInstances()
	local MapInstanceIds = {}

	for mapInstanceId, _ in MapInstanceIdToMapPositionIndex do
		table.insert(MapInstanceIds, mapInstanceId)
	end

	return MapInstanceIds
end
local function destroyAllMapInstances()
	for mapInstanceId, _ in MapInstanceIdToMapPositionIndex do
		destroyMapInstance(mapInstanceId)
	end
end

local function initializeMapTemplate(mapEnum, mapName)
	local MapModel = Utility.convertInstanceIntoModel(Assets.getExpectedAsset(`{mapName} MapFolder`))
	local MechanicsFolder = Assets.getExpectedAsset(`{mapName} MechanicsFolder`, `{mapName} MapFolder`, MapModel)

	local transparency = if TESTING_MODE then 0.8 else 1
	for _, BasePart in MechanicsFolder:GetDescendants() do
		if not (BasePart:IsA("BasePart")) then
			continue
		end

		BasePart.CanCollide = false
		BasePart.Anchored = true
		BasePart.Transparency = transparency
	end
end
local function initializeMapsServer()
	SoccerDuelsServer = require(SoccerDuelsServerModule)
	SoccerBallServer = require(SoccerDuelsServerModule.SoccerBallServer)

	local MapGridOriginPart = Assets.getExpectedAsset("MapGridOriginPart")
	mapGridOrigin = MapGridOriginPart.Position

	for mapEnum, mapName in Enums.iterateEnumsOfType("Map") do
		initializeMapTemplate(mapEnum, mapName)
	end

	Utility.runServiceSteppedConnect(MAP_STATE_TICK_RATE_SECONDS, mapTimerTick)
end

return {
	-- map state
	getMapInstanceState = getMapInstanceState,
	getPlayerTeamIndex = getPlayerTeamIndex,
	mapTimerTick = mapTimerTick,

	playerTackledAnotherPlayer = playerTackledAnotherPlayer,
	playerAssistedGoal = playerAssistedGoal,
	playerScoredGoal = playerScoredGoal,

	-- map instances
	disconnectPlayerFromAllMapInstances = disconnectPlayerFromAllMapInstances,
	getPlayersConnectedToMapInstance = getPlayersConnectedToMapInstance,
	getPlayerConnectedMapInstance = getPlayerConnectedMapInstance,
	connectPlayerToMapInstance = connectPlayerToMapInstance,
	playerIsInLobby = playerIsInLobby, --> TODO this should probably be defined in the SoccerDuelsServer module

	destroyAllMapInstances = destroyAllMapInstances,
	getAllMapInstances = getAllMapInstances,

	getMapInstanceStartingLocation = getMapInstanceStartingLocation,
	getPlayerThatScoredLastGoal = getPlayerThatScoredLastGoal,
	getMapInstanceWinningTeam = getMapInstanceWinningTeam,
	getMapInstanceMapName = getMapInstanceMapName,
	getMapInstanceFolder = getMapInstanceFolder,
	getMapInstanceOrigin = getMapInstanceOrigin,
	getMapInstanceScore = getMapInstanceScore,
	destroyMapInstance = destroyMapInstance,
	newMapInstance = newMapInstance,

	-- standard methods
	disconnectPlayer = disconnectPlayerFromAllMapInstances, -- this is invoked in SoccerDuelsServer.disconnectPlayer(), hence the duplicate method
	initialize = initializeMapsServer,
}
