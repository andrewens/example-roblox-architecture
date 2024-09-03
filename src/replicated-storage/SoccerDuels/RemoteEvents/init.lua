-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local RemoteEventsFolder = script.RemoteEvents

local Config = require(SoccerDuelsModule.Config)
local RemoteEventWrapper = require(script.RemoteEventWrapper)

-- public
if Config.getConstant("TestingMode") then
    RemoteEventWrapper.initialize()

    local RemoteEventWrappers = {}
    for _, RemoteEvent in RemoteEventsFolder:GetChildren() do
        RemoteEventWrappers[RemoteEvent.Name] = RemoteEventWrapper.new(RemoteEvent)
    end

    return RemoteEventWrappers
end

return RemoteEventsFolder
