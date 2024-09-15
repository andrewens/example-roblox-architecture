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
			end)
			--describe("Client:OnControllerTypeChangedConnect()", function()

			--end)
		end)
	end)
end
