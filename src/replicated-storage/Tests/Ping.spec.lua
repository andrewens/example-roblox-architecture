-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestsFolder = script:FindFirstAncestor("Tests")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(TestsFolder.MockInstance)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("Ping", function()
		it("We can get a player's ping in milliseconds from the client or the server", function()
			SoccerDuels.disconnectAllPlayers()
			SoccerDuels.resetTestingVariables()

			local maxErrorMilliseconds = 5
			local artificialLatencyMilliseconds = 100

			local Player1 = MockInstance.new("Player")
			local Player2 = MockInstance.new("Player")

			local Client1 = SoccerDuels.newClient(Player1)
			local Client2 = SoccerDuels.newClient(Player2)

			Client1:LoadPlayerDataAsync()
			Client2:LoadPlayerDataAsync()

			local start, elapsedMilliseconds, ping
			start = SoccerDuels.getUnixTimestampMilliseconds()

			SoccerDuels.pingPlayerAsync(Player1)

			elapsedMilliseconds = SoccerDuels.getUnixTimestampMilliseconds() - start
			ping = SoccerDuels.getPlayerPingMilliseconds(Player1)

			if not (math.abs(ping - elapsedMilliseconds) < maxErrorMilliseconds) then
				error(`{ping} != {elapsedMilliseconds}`)
			end
			assert(ping == SoccerDuels.getPlayerPingMilliseconds(Player1)) -- ping stays cached & gets replicated
			assert(Client1:GetPlayerPingMilliseconds(Player1) == ping)
			assert(Client2:GetPlayerPingMilliseconds(Player1) == ping)

			SoccerDuels.setTestingVariable("ExtraLoadTime", artificialLatencyMilliseconds * 0.001)
			start = SoccerDuels.getUnixTimestampMilliseconds()
			SoccerDuels.pingPlayerAsync(Player1)

			elapsedMilliseconds = (SoccerDuels.getUnixTimestampMilliseconds() - start)
			ping = SoccerDuels.getPlayerPingMilliseconds(Player1)

			if not (math.abs(ping - elapsedMilliseconds) < maxErrorMilliseconds) then
				error(`{ping} != {elapsedMilliseconds}`)
			end
            assert(elapsedMilliseconds > 2 * artificialLatencyMilliseconds) -- 2x because it goes both ways
			assert(Client1:GetPlayerPingMilliseconds(Player1) == ping)
			assert(Client2:GetPlayerPingMilliseconds(Player1) == ping)

			SoccerDuels.resetTestingVariables()

			Client1:Destroy()

			assert(SoccerDuels.getPlayerPingMilliseconds(Player1) == nil)
			assert(Client2:GetPlayerPingMilliseconds(Player1) == nil)

			Client2:Destroy()

			assert(SoccerDuels.getPlayerPingMilliseconds(Player2) == nil)
		end)
	end)
end
