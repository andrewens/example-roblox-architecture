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

			SoccerDuels.setTestingVariable("ExtraLoadTime", artificialLatencyMilliseconds * 1E-3)
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
		it(
			"A player's ping quality can be 'Good', 'Okay', or 'Bad', which can be looked up on the server or client",
			function()
				SoccerDuels.disconnectAllPlayers()
				SoccerDuels.resetTestingVariables()

				local maxGoodPingMs = SoccerDuels.getConstant("PingQualityThresholdMilliseconds", "Good")
				local maxOkayPingMs = SoccerDuels.getConstant("PingQualityThresholdMilliseconds", "Okay")
				local placeHolderPingQuality = SoccerDuels.getConstant("PlaceholderPingQuality")

				local Player1 = MockInstance.new("Player")
				local Player2 = MockInstance.new("Player")

				local Client1 = SoccerDuels.newClient(Player1)
				local Client2 = SoccerDuels.newClient(Player2)

				assert(SoccerDuels.getPlayerPingQuality(Player1) == placeHolderPingQuality)
				assert(Client1:GetPlayerPingQuality(Player1) == placeHolderPingQuality)
				assert(Client2:GetPlayerPingQuality(Player1) == placeHolderPingQuality)

				Client2:LoadPlayerDataAsync()

				-- (event)
				local changeCount = 0
				local LastPlayer, lastPingQuality
				local function callback(...)
					changeCount += 1
					LastPlayer, lastPingQuality = ...
				end

				local conn = Client2:OnPlayerPingQualityChangedConnect(callback)

				assert(changeCount == 1)
				assert(LastPlayer == Player2)
				assert(lastPingQuality == placeHolderPingQuality)

				Client1:LoadPlayerDataAsync()

				assert(changeCount == 2)
				assert(LastPlayer == Player1)
				assert(lastPingQuality == placeHolderPingQuality)

				if placeHolderPingQuality ~= "Good" then -- Player2's ping quality should stay at 'Good' for the rest of the test to avoid extra latency
					SoccerDuels.pingPlayerAsync(Player2)

					assert(changeCount == 3)
					assert(LastPlayer == Player2)
					assert(lastPingQuality == "Good")
				end

                changeCount = 0

				-- good
				local maxErrorMs = 20 -- lower error thresholds will not reliably make the latency within the desired range
				local artificialLatencyMs = math.floor(maxGoodPingMs * 0.5) - maxErrorMs

				SoccerDuels.setTestingVariable("ExtraLoadTime", artificialLatencyMs * 1E-3)

				local start = SoccerDuels.getUnixTimestampMilliseconds()
				SoccerDuels.pingPlayerAsync(Player1)
				local elapsedMilliseconds = SoccerDuels.getUnixTimestampMilliseconds() - start

				assert(math.abs(elapsedMilliseconds) <= maxGoodPingMs)
				assert(SoccerDuels.getPlayerPingQuality(Player1) == "Good")
				assert(Client1:GetPlayerPingQuality(Player1) == "Good")
				assert(Client2:GetPlayerPingQuality(Player1) == "Good")

				-- (event)
				if placeHolderPingQuality == "Good" then
					assert(changeCount == 0)
					assert(LastPlayer == Player1)
					assert(lastPingQuality == placeHolderPingQuality)
				else
					assert(changeCount == 1)
					assert(LastPlayer == Player1)
					assert(lastPingQuality == "Good")
				end

                changeCount = 0

				-- okay
				artificialLatencyMs = math.floor(maxOkayPingMs * 0.5) - maxErrorMs

				SoccerDuels.setTestingVariable("ExtraLoadTime", artificialLatencyMs * 1E-3)

				start = SoccerDuels.getUnixTimestampMilliseconds()
				SoccerDuels.pingPlayerAsync(Player1)
				elapsedMilliseconds = SoccerDuels.getUnixTimestampMilliseconds() - start

				assert(elapsedMilliseconds > maxGoodPingMs)
				assert(elapsedMilliseconds <= maxOkayPingMs)
				assert(SoccerDuels.getPlayerPingQuality(Player1) == "Okay")
				assert(Client1:GetPlayerPingQuality(Player1) == "Okay")
				assert(Client2:GetPlayerPingQuality(Player1) == "Okay")

                -- (event)
                assert(changeCount == 1)
                assert(LastPlayer == Player1)
                assert(lastPingQuality == "Okay")

                changeCount = 0

				-- bad
				artificialLatencyMs = math.ceil(maxOkayPingMs * 0.5) + maxErrorMs -- plus sign instead of minus to get over the 'okay' threshold into 'bad'

				SoccerDuels.setTestingVariable("ExtraLoadTime", artificialLatencyMs * 1E-3)

				start = SoccerDuels.getUnixTimestampMilliseconds()
				SoccerDuels.pingPlayerAsync(Player1)
				elapsedMilliseconds = SoccerDuels.getUnixTimestampMilliseconds() - start

				assert(elapsedMilliseconds > maxOkayPingMs)
				assert(SoccerDuels.getPlayerPingQuality(Player1) == "Bad")
				assert(Client1:GetPlayerPingQuality(Player1) == "Bad")
				assert(Client2:GetPlayerPingQuality(Player1) == "Bad")

                -- (event)
                assert(changeCount == 1)
                assert(LastPlayer == Player1)
                assert(lastPingQuality == "Bad")

                changeCount = 0

				-- placeholder
				SoccerDuels.resetTestingVariables()
				Client1:Destroy()

				assert(SoccerDuels.getPlayerPingQuality(Player1) == placeHolderPingQuality)
				assert(Client2:GetPlayerPingQuality(Player1) == placeHolderPingQuality)

                -- (event)
                if placeHolderPingQuality == "Bad" then
					assert(changeCount == 0)
					assert(LastPlayer == Player1)
					assert(lastPingQuality == placeHolderPingQuality)
				else
					assert(changeCount == 1)
					assert(LastPlayer == Player1)
					assert(lastPingQuality == placeHolderPingQuality)
				end

                changeCount = 0

                conn:Disconnect()
				Client2:Destroy()

                assert(changeCount == 0)
			end
		)
	end)
end
