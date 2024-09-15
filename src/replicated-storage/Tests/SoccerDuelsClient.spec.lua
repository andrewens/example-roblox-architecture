-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local MockInstance = require(ReplicatedStorage.MockInstance)

-- test
return function()
	describe("SoccerDuels client", function()
		describe("Platform-agnostic controller", function()
			describe("Client:GetControllerType()", function()
				it(
					"Returns a string describing if the user is using a keyboard/mouse, gamepad, or touch screen based off of most recent input",
					function()
						SoccerDuels.resetTestingVariables()

						local Client = SoccerDuels.newClient(MockInstance.new("Player"))

						-- default controller type
						local defaultControllerType = SoccerDuels.getConstant("DefaultControllerType")
						local prevControllerType = Client:GetControllerType()

						assert(prevControllerType == defaultControllerType)

						-- testing every UserInputType versus the platform it corresponds to
						local TEST_CASES = {
							-- { UserInputType, ControllerType (nil=same as before) }

							{ "MouseButton1", "Keyboard" },
							{ "MouseButton2", "Keyboard" },
							{ "MouseButton3", "Keyboard" },
							{ "MouseWheel", "Keyboard" },
							{ "MouseMovement", "Keyboard" },
							{ "Touch", "Touch" },
							{ "Keyboard", "Keyboard" },
							{ "Focus", nil },
							{ "Accelerometer", "Touch" },
							{ "Gyro", "Touch" },
							{ "Gamepad1", "Gamepad" },
							{ "Gamepad2", "Gamepad" },
							{ "Gamepad3", "Gamepad" },
							{ "Gamepad4", "Gamepad" },
							{ "Gamepad5", "Gamepad" },
							{ "Gamepad6", "Gamepad" },
							{ "Gamepad7", "Gamepad" },
							{ "Gamepad8", "Gamepad" },
							{ "TextInput", nil },
							{ "InputMethod", nil },
							-- { "Unknown", nil }, -- this isn't actually a UserInputType enum :/

							-- UserInputTypes taken from roblox documentation:
							-- https://create.roblox.com/docs/reference/engine/enums/UserInputType
						}

						for i, TestCase in TEST_CASES do
							local InputObject = MockInstance.new("InputObject", {
								UserInputType = Enum.UserInputType[TestCase[1]],
							})
							Client:TapInput(InputObject)

							local newControllerType = Client:GetControllerType()
							if TestCase[2] then
								if not (newControllerType == TestCase[2]) then
									error(
										`Client:GetControllerType() returned "{newControllerType}", which isn't "{TestCase[2]}" (TEST CASE #{i})`
									)
								end
							else
								if not (newControllerType == prevControllerType) then
									error(
										`Client:GetControllerType() returned "{newControllerType}", which isn't "{prevControllerType}" (TEST CASE #{i})`
									)
								end
							end

							prevControllerType = newControllerType
						end

						Client:Destroy()
					end
				)
				it("Client's controller type is replicated to all other clients", function()
					SoccerDuels.resetTestingVariables()
					SoccerDuels.disconnectAllPlayers()

					local Player1 = MockInstance.new("Player")
					local Player2 = MockInstance.new("Player")

					Player1.Name = "Greg"
					Player2.Name = "Margaret"

					local Client1 = SoccerDuels.newClient(Player1)
					local Client2 = SoccerDuels.newClient(Player2)

					Client1:LoadPlayerDataAsync()
					Client2:LoadPlayerDataAsync()
					Client1:TapInput(MockInstance.new("InputObject", { UserInputType = Enum.UserInputType.Keyboard }))

					local defaultControllerType = SoccerDuels.getConstant("DefaultControllerType")

					if not (Client1:GetControllerType() == "Keyboard") then
						error(`{Client1:GetControllerType()} != "Keyboard"`)
					end
					assert(Client1:GetControllerType(Player1) == "Keyboard")
					assert(Client2:GetControllerType(Player1) == "Keyboard")
					assert(Client1:GetControllerType(Player2) == defaultControllerType)
					assert(Client2:GetControllerType() == defaultControllerType)
					assert(Client2:GetControllerType(Player2) == defaultControllerType)

					Client2:TapInput(MockInstance.new("InputObject", { UserInputType = Enum.UserInputType.Gamepad1 }))

					assert(Client1:GetControllerType() == "Keyboard")
					assert(Client1:GetControllerType(Player1) == "Keyboard")
					assert(Client2:GetControllerType(Player1) == "Keyboard")
					assert(Client1:GetControllerType(Player2) == "Gamepad")
					assert(Client2:GetControllerType() == "Gamepad")
					assert(Client2:GetControllerType(Player2) == "Gamepad")

					Client1:TapInput(MockInstance.new("InputObject", { UserInputType = Enum.UserInputType.Touch }))

					assert(Client1:GetControllerType() == "Touch")
					assert(Client1:GetControllerType(Player1) == "Touch")
					assert(Client2:GetControllerType(Player1) == "Touch")
					assert(Client1:GetControllerType(Player2) == "Gamepad")
					assert(Client2:GetControllerType() == "Gamepad")
					assert(Client2:GetControllerType(Player2) == "Gamepad")

					Client1:Destroy()
					Client2:Destroy()
				end)
			end)
			describe("Client:OnControllerTypeChangedConnect()", function()
				it("Connects a callback to whenever the client's controller changes", function()
					SoccerDuels.resetTestingVariables()

					local Client = SoccerDuels.newClient(MockInstance.new("Player"))
					Client:TapInput(MockInstance.new("InputObject", { UserInputType = Enum.UserInputType.Keyboard }))

					local changeCount = 0
					local prevControllerType
					local conn = Client:OnControllerTypeChangedConnect(function(newControllerType)
						changeCount += 1
						prevControllerType = newControllerType
					end)

					assert(changeCount == 1)
					assert(prevControllerType == "Keyboard")

					local TEST_CASES = {
						-- { UserInputType, ControllerType, changeCount }

						{ "MouseButton1", "Keyboard", 1 },
						{ "Gamepad1", "Gamepad", 2 },
						{ "MouseButton2", "Keyboard", 3 },
						{ "MouseButton3", "Keyboard", 3 },
						{ "Gyro", "Touch", 4 },
						{ "Focus", "Touch", 4 },
						{ "MouseWheel", "Keyboard", 5 },
						{ "MouseMovement", "Keyboard", 5 },
						{ "Touch", "Touch", 6 },
						{ "Keyboard", "Keyboard", 7 },
						{ "Accelerometer", "Touch", 8 },
						{ "Gamepad2", "Gamepad", 9 },
						{ "TextInput", "Gamepad", 9 },
						{ "Gamepad3", "Gamepad", 9 },
						{ "Gamepad4", "Gamepad", 9 },
						{ "Gamepad5", "Gamepad", 9 },
						{ "Gamepad6", "Gamepad", 9 },
						{ "Gamepad7", "Gamepad", 9 },
						{ "Gamepad8", "Gamepad", 9 },
					}

					for i, TestCase in TEST_CASES do
						Client:TapInput(MockInstance.new("InputObject", {
							UserInputType = Enum.UserInputType[TestCase[1]],
						}))

						if not (changeCount == TestCase[3]) then
							error(`changeCount = {changeCount}, which isn't {TestCase[3]} (FAILS TEST CASE #{i})`)
						end
						if not (prevControllerType == TestCase[2]) then
							error(
								`prevControllerType = "{prevControllerType}", which isn't "{TestCase[2]}" (TEST CASE #{i})`
							)
						end
					end

					-- no more changes after disconnect
					conn:Disconnect()
					Client:TapInput(MockInstance.new("InputObject", { UserInputType = Enum.UserInputType.Keyboard }))

					assert(changeCount == 9)
					assert(prevControllerType == "Gamepad")

					Client:Destroy()
				end)
			end)
		end)
	end)
end
