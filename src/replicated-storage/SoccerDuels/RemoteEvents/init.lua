-- dependency
local RemoteEventsFolder = script.RemoteEvents

local RemoteEventWrapper = require(script.RemoteEventWrapper)

-- public
RemoteEventWrapper.initialize()

local RemoteEventWrappers = {}
for _, RemoteEvent in RemoteEventsFolder:GetChildren() do
    RemoteEventWrappers[RemoteEvent.Name] = RemoteEventWrapper.new(RemoteEvent)
end

return RemoteEventWrappers
