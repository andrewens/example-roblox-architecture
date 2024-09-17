-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Enums = require(SoccerDuelsModule.Enums)

-- var
local MaxPlayersPerTeam = {} -- int matchPadEnum --> int

-- private
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

-- public
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
end

return {
	getMatchJoiningPads = getMatchJoiningPads,
	initialize = initializeMatchJoiningPads,
}
