-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)

-- private
local function tableDeepEqual(Table1, Table2)
	if typeof(Table1) == "table" and typeof(Table2) == "table" then
		for k, v in Table1 do
			if not tableDeepEqual(v, Table2[k]) then
				return false, `{v} != {Table2[k]} (key: "{k}")`
			end
		end
		for k, v in Table2 do -- redundant, but avoids extra memory
			if not tableDeepEqual(v, Table1[k]) then
				return false, `{v} != {Table1[k]} (key: "{k}")`
			end
		end

		return true
	end

    if Table1 ~= Table2 then
        return false, `{Table1} != {Table2}`
    end

    return true
end

-- test
return function()
	describe("SoccerDuels database", function()
		describe("Client:LoadPlayerDataAsync()", function()
			it("Loads the user's saved data onto the client, returning a boolean representing if it was successful", function()
                local MockPlayer = MockInstance.new("Player")
                local Client = SoccerDuels.newClient(MockPlayer)

                assert(nil == Client:GetPlayerSaveData())

                local success = Client:LoadPlayerDataAsync() -- because this is in testing mode, it's not actually async here
                local PlayerSaveData = Client:GetPlayerSaveData()

                assert(typeof(success) == "boolean")
                assert(typeof(PlayerSaveData) == "table")

                -- should load default data for our player
                local DefaultPlayerSaveData = SoccerDuels.getConstant("DefaultPlayerSaveData")

                assert(tableDeepEqual(DefaultPlayerSaveData, PlayerSaveData))
			end)
		end)
	end)
end
