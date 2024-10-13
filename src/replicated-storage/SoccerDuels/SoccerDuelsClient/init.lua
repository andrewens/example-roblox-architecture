-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientStateFolder = script.State

local Config = require(SoccerDuelsModule.Config)
local Enums = require(SoccerDuelsModule.Enums)
local Maid = require(SoccerDuelsModule.Maid)
local Network = require(SoccerDuelsModule.Network)
local PlayerDocument = require(SoccerDuelsModule.PlayerDocument)
local Utility = require(SoccerDuelsModule.Utility)

local Gui = require(script.Gui)

local ClientInput = require(SoccerDuelsClientStateFolder.ClientInput)
local ClientMapState = require(SoccerDuelsClientStateFolder.ClientMapState)
local ClientMatchPad = require(SoccerDuelsClientStateFolder.ClientMatchPad)
local ClientModalState = require(SoccerDuelsClientStateFolder.ClientModalState)
local ClientPing = require(SoccerDuelsClientStateFolder.ClientPing)
local ClientSettings = require(SoccerDuelsClientStateFolder.ClientSettings)
local ClientToastNotificationState = require(SoccerDuelsClientStateFolder.ClientToastNotificationState)
local ClientUserInterfaceMode = require(SoccerDuelsClientStateFolder.ClientUserInterfaceMode)
local LoadClientSaveData = require(SoccerDuelsClientStateFolder.LoadClientSaveData)
local LobbyCharacters = require(SoccerDuelsClientStateFolder.LobbyCharacters)

-- var
local ClientMetatable

-- public / Client class methods
local function destroyClient(self) -- TODO this isn't really tested
	self._Maid:DoCleaning()

	self._UserInterfaceModeChangedCallbacks = nil
	self._ControllerTypeChangedCallbacks = nil
	self._LobbyCharacterSpawnedCallbacks = nil
	self._VisibleModalChangedCallbacks = nil
	self._PlayerDataLoadedCallbacks = nil
	self._SettingChangedCallbacks = nil
	self._ToastCallbacks = nil

	self._MatchJoiningPadStateChangeTimestamp = nil
	self._ImageLabelsWaitingForAvatarImages = nil
	self._MatchJoiningPadStateEnum = nil
	self._CachedPlayerAvatarImages = nil
	self._CharactersInLobby = nil

	Gui.destroy(self)

	Network.fireServer("ClientDestroyed", self.Player)
end

-- public
local function getAnyPlayerTeamIndex(self, Player)
	Player = Player or self.Player
	return self._PlayerTeamIndex[Player] or self._PlayerConnectedMatchPadTeam[Player]
end
local function newClient(Player)
	if not (Utility.isA(Player, "Player")) then
		error(`{Player} is not a Player Instance!`)
	end

	-- public properties
	local self = {}
	self.Player = Player

	-- private properties (don't use outside of client modules)
	self._Maid = Maid.new() -- cleans on self:Destroy() and self:LoadPlayerDataAsync()
	self._MainGui = nil -- ScreenGui

	self._VisibleModalEnum = nil -- int | nil
	self._VisibleModalChangedCallbacks = {} -- function callback(string visibleModalName) --> true

	self._PlayerSaveData = {} -- Player --> PlayerDocument
	self._PlayerDataLoadedCallbacks = {} -- function callback(table PlayerSaveData) --> true
	self._SettingChangedCallbacks = {} -- function callback(string settingName, any settingValue) --> true

	self._ToastCallbacks = {} -- function callback(string notificationMessage) --> true

	self._LobbyCharacterSpawnedCallbacks = {} -- function callback(Model Character, Player PlayerThatSpawned) --> true
	self._CharactersInLobby = {} -- Player --> Character

	self._ControllerTypeEnum = {} -- Player --> int controllerTypeEnum
	self._ControllerTypeChangedCallbacks = {} -- function callback(string controllerType, Player AnyPlayer) --> true

	self._UserInterfaceModeEnum = Enums.getEnum("UserInterfaceMode", "None") -- int
	self._UserInterfaceModeChangedCallbacks = {} -- function callback(string userInterfaceMode)

	self._MatchJoiningPadStateEnum = {} -- int matchPadEnum --> int matchPadStateEnum
	self._MatchJoiningPadStateChangeTimestamp = {} -- int matchPadEnum --> int | nil stateChangeTimestamp
	self._PlayerConnectedMatchPadEnum = {} -- Player --> int matchPadEnum
	self._PlayerConnectedMatchPadTeam = {} -- Player --> int teamIndex
	self._PlayerMatchPadChangedCallbacks = {} -- function callback(Player AnyPlayer, string | nil matchPadName, int teamIndex)
	self._CharacterTouchedMatchPadCallbacks = {} -- function callback(string matchPadName, int teamIndex) --> true
	self._PlayerConnectedMatchPadStateChangedCallbacks = {} -- function callback(string matchPadStateName, int | nil matchStateChangeTimestamp) --> true

	self._PlayerMapVotes = {} -- Player --> mapEnum | nil (only players in client's connected match joining pad!)
	self._PlayerVotedOnMapCallbacks = {} -- function callback(Player AnyPlayer, string | nil mapName) --> true

	self._CachedPlayerAvatarImages = {} -- int userId --> string imageContent
	self._ImageLabelsWaitingForAvatarImages = {} -- int userId --> [ ImageLabel, ... ]

	self._PlayerPingMilliseconds = {} -- Player --> int playerPingMilliseconds
	self._PlayerPingQualityChangedCallbacks = {} -- function callback(Player, string pingQuality) --> true

	self._PlayerConnectedMapEnum = {} -- Player --> int mapEnum
	self._PlayerTeamIndex = {} -- Player --> int teamIndex (for when players are in a match)
	self._PlayerGoals = {} -- Player --> int numGoalsScored (only players in same map as self.Player)
	self._PlayerAssists = {} -- Player --> int numAssists (only players in same map as self.Player)
	self._PlayerTackles = {} -- Player --> int numTackles (only players in same map as self.Player)
	self._PlayerLeaderstatsChangedCallbacks = {} -- function callback(Player, int | nil teamIndex, int | nil numGoals, ...) --> true

	self._ConnectedMapStateEnum = nil -- int | nil mapStateEnum
	self._ConnectedMapStateEndTimestamp = nil -- int | nil unixTimestampMilliseconds

	-- init
	setmetatable(self, ClientMetatable)

	Gui.new(self)
	ClientToastNotificationState.initializeClientToastNotifications(self)

	return self
end
local function initializeClients()
	local ClientMethods = {
		-- lobby characters
		OnCharacterSpawnedInLobbyConnect = LobbyCharacters.clientOnCharacterSpawnedInLobbyConnect,
		LobbyCharacterTouchedPart = LobbyCharacters.partTouchedClientLobbyCharacter,
		GetCharactersInLobby = LobbyCharacters.getCharactersInLobby,

		-- map state
		GetConnectedMapStateChangeTimestamp = ClientMapState.getClientMapStateChangeTimestamp,
		OnPlayerLeaderstatsChangedConnect = ClientMapState.onPlayerLeaderstatsChangedConnect,
		GetConnectedMapName = ClientMapState.getClientConnectedMapName,
		-- GetPlayerTeamIndex = getAnyPlayerTeamIndex,

		-- map voting
		VoteForMap = ClientMatchPad.clientVoteForMap,
		OnConnectedMatchPadVoteChangedConnect = ClientMatchPad.onClientConnectedMatchPadVoteChangedConnect,
		GetPlayerTeamIndex = getAnyPlayerTeamIndex,

		-- match joining pad
		DisconnectFromMatchJoiningPadIfCharacterSteppedOffAsync = ClientMatchPad.disconnectClientFromMatchPadIfCharacterSteppedOffAsync,
		OnPlayerMatchPadStateChangedConnect = ClientMatchPad.onPlayerConnectedMatchPadStateChangedConnect,
		OnLobbyCharacterTouchedMatchPadConnect = ClientMatchPad.onLobbyCharacterTouchedMatchPadConnect,
		OnPlayerMatchPadChangedConnect = ClientMatchPad.onAnyPlayerMatchPadChangedConnect,
		TeleportToMatchPadAsync = ClientMatchPad.clientTeleportToMatchPadAsync,

		GetMatchPadMaxPlayersPerTeam = ClientMatchPad.getAnyMatchPadMaxTeamPlayers,
		GetMatchPadState = ClientMatchPad.getAnyMatchPadState,
		MatchPadIsFull = ClientMatchPad.anyMatchPadIsFull,
		MatchPadIsEmpty = ClientMatchPad.anyMatchPadIsEmpty,

		GetConnectedMatchPadStateChangeTimestamp = ClientMatchPad.getClientConnectedMatchPadStateChangeTimestamp, -- TODO untested
		GetConnectedMatchPadMaxPlayersPerTeam = ClientMatchPad.getClientConnectedMatchPadMaxPlayers, -- TODO untested
		GetConnectedMatchPadName = ClientMatchPad.getClientConnectedMatchPadName,
		GetConnectedMatchPadTeam = ClientMatchPad.getClientConnectedMatchPadTeam,

		-- modal state
		OnVisibleModalChangedConnect = ClientModalState.clientOnVisibleModalChangedConnect,
		ToggleModalVisibility = ClientModalState.toggleClientModalVisibility,
		GetVisibleModalName = ClientModalState.getClientVisibleModalName,
		SetVisibleModalName = ClientModalState.setClientVisibleModal,

		-- ping
		OnPlayerPingQualityChangedConnect = ClientPing.onPlayerPingQualityChangeConnect,
		GetPlayerPingMilliseconds = ClientPing.getPlayerPingMilliseconds,
		GetPlayerPingQuality = ClientPing.getPlayerPingQuality,

		-- toast notification
		OnToastNotificationConnect = ClientToastNotificationState.onClientToastNotificationConnect,

		-- user input
		OnControllerTypeChangedConnect = ClientInput.onClientControllerTypeChangedConnect,
		GetControllerType = ClientInput.getClientControllerType,
		TapInput = ClientInput.clientTapInput,

		-- user interface mode
		OnUserInterfaceModeChangedConnect = ClientUserInterfaceMode.onClientUserInterfaceModeChangedConnect,
		GetUserInterfaceMode = ClientUserInterfaceMode.getClientUserInterfaceMode,

		-- save data
		OnPlayerSaveDataLoadedConnect = LoadClientSaveData.onClientPlayerDataLoadedConnect,
		GetAnyPlayerDataValue = LoadClientSaveData.getAnyPlayerDataCachedValue,
		LoadPlayerDataAsync = LoadClientSaveData.loadClientPlayerDataAsync,
		PlayerDataIsLoaded = LoadClientSaveData.clientPlayerDataIsLoaded,
		GetPlayerSaveData = LoadClientSaveData.getAnyPlayerCachedSaveData,

		-- settings
		OnSettingChangedConnect = ClientSettings.onClientSettingChangedConnect,
		ToggleBooleanSetting = ClientSettings.clientToggleBooleanSetting,
		ChangeSetting = ClientSettings.clientChangeSetting,
		GetSetting = ClientSettings.getClientSettingValue,
		GetSettings = ClientSettings.getClientSettingsJson,

		-- client root
		Destroy = destroyClient,
	}
	ClientMetatable = { __index = ClientMethods }

	ClientInput.initialize()
end

return {
	new = newClient,
	initialize = initializeClients,
}
