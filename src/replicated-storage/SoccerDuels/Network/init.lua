--[[
    The Network module allows us to run client-server tests on the server only.

    It works by supporting two interfaces:
        - An interface for testing mode, which supports client behavior on the server
        - A normal interface for using RemoteEvents normally

    The function signatures must all be the same so that the rest of the SoccerDuels
    code doesn't have to take this into account -- hence the redundant Player arguments.

    September 11, 2024
    Andrew Ens
]]

-- dependency
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local RemoteEvents = script.RemoteEvents

local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local TESTING_MODE = Config.getConstant("TestingMode")
local IS_SERVER = RunService:IsServer()

-- public
if not TESTING_MODE then
	local function fireServer(remoteName, Player, ...)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not Utility.isA(Player, "Player") then
			error(`{Player} is not a Player!`)
		end

		local RemoteEvent = RemoteEvents[remoteName]
		RemoteEvent:FireServer(...)
	end
	local function fireClient(remoteName, Player, ...)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not Utility.isA(Player, "Player") then
			error(`{Player} is not a Player!`)
		end

		local RemoteEvent = RemoteEvents[remoteName]
		RemoteEvent:FireClient(Player, ...)
	end
	local function fireAllClients(remoteName, ...)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end

		local RemoteEvent = RemoteEvents[remoteName]
		RemoteEvent:FireAllClients(...)
	end
	local function onClientEventConnect(remoteName, Player, callback)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not Utility.isA(Player, "Player") then
			error(`{Player} is not a Player!`)
		end
		if not (typeof(callback) == "function") then
			error(`{callback} is not a function!`)
		end

		local RemoteEvent = RemoteEvents[remoteName]

		return RemoteEvent.OnClientEvent:Connect(callback)
	end
	local function onServerEventConnect(remoteName, callback)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not (typeof(callback) == "function") then
			error(`{callback} is not a function!`)
		end

		local RemoteEvent = RemoteEvents[remoteName]

		return RemoteEvent.OnServerEvent:Connect(callback)
	end

	local function invokeServer(remoteName, Player, ...)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not Utility.isA(Player, "Player") then
			error(`{Player} is not a Player!`)
		end

		local RemoteFunction = RemoteEvents[remoteName]
		RemoteFunction:InvokeServer(...)
	end
	local function onServerInvokeConnect(remoteName, callback)
		if not (typeof(remoteName) == "string") then
			error(`{remoteName} is not a string!`)
		end
		if not (typeof(callback) == "function") then
			error(`{callback} is not a function!`)
		end

		local RemoteFunction = RemoteEvents[remoteName]
		RemoteFunction.OnServerInvoke = callback
	end

	return {
		-- RemoteEvent
		fireServer = fireServer,
		fireClient = fireClient,
		fireAllClients = fireAllClients,
		onClientEventConnect = onClientEventConnect,
		onServerEventConnect = onServerEventConnect,

		-- RemoteFunction (intentionally did not implement invokeClient because it's bad practice to use it)
		invokeServer = invokeServer,
		onServerInvokeConnect = onServerInvokeConnect,
	}
end

-- var
local OnServerInvoke = {} -- string remoteName --> function callback(Player, ...)
local OnServerEvent = {} -- string remoteName --> { function callback(Player, ...) --> true }
local OnClientEvent = {} -- string remoteName --> table MockPlayer --> { function callback(...) --> true }

-- public / TESTING_MODE
local function fireServerTestingMode(remoteName, Player, ...)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local RemoteEvent = RemoteEvents[remoteName]

	if IS_SERVER then
		if OnServerEvent[remoteName] then
			for callback, _ in OnServerEvent[remoteName] do
				callback(Player, ...)
			end
		end

		return
	end

	RemoteEvent:FireServer(...)
end
local function fireClientTestingMode(remoteName, Player, ...)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local RemoteEvent = RemoteEvents[remoteName]

	if OnClientEvent[remoteName] and OnClientEvent[remoteName][Player] then
		for callback, _ in OnClientEvent[remoteName][Player] do
			callback(...)
		end
	end

	if typeof(Player) == "Instance" then
		RemoteEvent:FireClient(Player, ...) -- this should hopefully never run on the client
	end
end
local function fireAllClientsTestingMode(remoteName, ...)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end

	local RemoteEvent = RemoteEvents[remoteName]

	if OnClientEvent[remoteName] then
		for Player, Callbacks in OnClientEvent[remoteName] do
			for callback, _ in Callbacks do
				callback(...)
			end
		end
	end

	RemoteEvent:FireAllClients(...) -- this should hopefully never run on the client
end
local function onClientEventConnectTestingMode(remoteName, Player, callback)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local RemoteEvent = RemoteEvents[remoteName]

	OnClientEvent[remoteName] = OnClientEvent[remoteName] or {}
	OnClientEvent[remoteName][Player] = OnClientEvent[remoteName][Player] or {}
	OnClientEvent[remoteName][Player][callback] = true

	local conn
	if not IS_SERVER then
		conn = RemoteEvent.OnClientEvent:Connect(callback)
	end

	return {
		Disconnect = function()
			OnClientEvent[remoteName][Player][callback] = nil
			if conn then
				conn:Disconnect()
			end
		end,
	}
end
local function onServerEventConnectTestingMode(remoteName, callback)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local RemoteEvent = RemoteEvents[remoteName]

	OnServerEvent[remoteName] = OnServerEvent[remoteName] or {}
	OnServerEvent[remoteName][callback] = true

	local conn = RemoteEvent.OnServerEvent:Connect(callback)

	return {
		Disconnect = function()
			OnServerEvent[remoteName][callback] = nil
			conn:Disconnect()
		end,
	}
end

local function invokeServerTestingMode(remoteName, Player, ...)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	local RemoteFunction = RemoteEvents[remoteName]

	if IS_SERVER then
		if OnServerInvoke[remoteName] then
			return OnServerInvoke[remoteName](Player, ...)
		end

		return -- should consider making this yield forever like it does if there's no OnServerInvoke hooked up
	end

	return RemoteFunction:InvokeServer(...)
end
local function onServerInvokeConnectTestingMode(remoteName, callback)
	if not (typeof(remoteName) == "string") then
		error(`{remoteName} is not a string!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	local RemoteFunction = RemoteEvents[remoteName]

	OnServerInvoke[remoteName] = callback

	RemoteFunction.OnServerInvoke = callback
end

return {
	-- RemoteEvent
	fireServer = fireServerTestingMode,
	fireClient = fireClientTestingMode,
	fireAllClients = fireAllClientsTestingMode,
	onClientEventConnect = onClientEventConnectTestingMode,
	onServerEventConnect = onServerEventConnectTestingMode,

	-- RemoteFunction (intentionally did not implement invokeClient because it's bad practice to use it)
	invokeServer = invokeServerTestingMode,
	onServerInvokeConnect = onServerInvokeConnectTestingMode,
}
