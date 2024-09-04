--[[
    In order to run Client/Server tests on the Server only, we need to create an object
    that functions equivalently to RemoteEvents & RemoteFunctions, but allows us to
    run client-only code on the server.

    It also needs to invoke events immediately so that tested methods are synchronous.

    This object is not defined in the MockInstance library because then the SoccerDuels
    API would have an external dependency, which I'm trying to avoid.

    September 3, 2024
    Andrew Ens
]]

-- dependency
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Event = require(SoccerDuelsModule.Event)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")

-- var
local InstanceWrapperMetatable

-- public / InstanceWrapper metamethods
local function indexInstanceWrapper(self, key)
	return self._Instance[key]
end
local function newIndexInstanceWrapper(self, key, value)
	if TESTING_MODE and key == "OnServerInvoke" then
		rawset(self, "_OnServerInvoke", value)
	end

	self._Instance[key] = value
end

-- public / RemoteFunction class methods
local function remoteFunctionWrapperInvokeServer(self, Player, ...)
	if RunService:IsClient() then
		if Players.LocalPlayer == Player then
			return self._Instance:InvokeServer(self, ...)
		end

		return self._Instance:InvokeServer(self, Player, ...)
	end

	if TESTING_MODE then
		local onServerInvokeCallback = rawget(self, "_OnServerInvoke")
		if onServerInvokeCallback then
			return onServerInvokeCallback(Player, ...)
		end
	end
end
local function remoteFunctionWrapperInvokeClient(self, ...)
	error("Please don't use this method")
end

-- public / RemoteEvent class methods
local function remoteEventWrapperFireServer(self, ...)
	if RunService:IsClient() then
		self._Instance:FireServer(...)
	end
end
local function remoteEventWrapperFireClient(self, Player, ...)
	if RunService:IsClient() then
		error(`{self.Name}:FireClient() can't be invoked on the client`)
	end

	if typeof(Player) == "Instance" then
		if not (Player:IsA("Player")) then
			error(`{Player} is not a Player!`)
		end
		if Players:FindFirstChild(Player.Name) == nil then
			return
		end

		self._Instance:FireClient(Player, ...)
	end

	if TESTING_MODE then
		self.OnClientEvent:Fire(...)
	end
end
local function remoteEventWrapperFireAllClients(self, ...)
	if RunService:IsServer() then
		self._Instance:FireAllClients(...)
	end
end

-- public
local function newRemoteEventWrapper(RemoteEvent)
	if not (typeof(RemoteEvent) == "Instance") then
		error(`{RemoteEvent} is not an Instance!`)
	end
	if not (RemoteEvent:IsA("RemoteEvent") or RemoteEvent:IsA("RemoteFunction")) then
		error(`{RemoteEvent} is not a RemoteEvent or RemoteFunction!`)
	end

	local self = {}
	self._Instance = RemoteEvent

	if RemoteEvent:IsA("RemoteEvent") then
		self.FireClient = remoteEventWrapperFireClient
		self.FireAllClients = remoteEventWrapperFireAllClients
		self.FireServer = remoteEventWrapperFireServer

		if TESTING_MODE then
			self.OnClientEvent = Event.new()
			self.OnServerEvent = Event.new()
		end
	else -- RemoteFunction
		self.InvokeServer = remoteFunctionWrapperInvokeServer
		self.InvokeClient = remoteFunctionWrapperInvokeClient
	end

	setmetatable(self, InstanceWrapperMetatable)

	return self
end
local function initializeRemoteEventWrapper()
	InstanceWrapperMetatable = {
		__index = indexInstanceWrapper,
		__newindex = newIndexInstanceWrapper,
	}
end

return {
	new = newRemoteEventWrapper,
	initialize = initializeRemoteEventWrapper,
}
