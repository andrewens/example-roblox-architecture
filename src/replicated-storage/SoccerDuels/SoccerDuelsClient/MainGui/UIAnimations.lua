-- dependency
local TweenService = game:GetService("TweenService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)

-- const
local BUTTON_CLICK_TWEEN_INFO = Config.getConstant("ButtonClickTweenInfo")
local BUTTON_CLICK_SIZE = Config.getConstant("ButtonClickSize")
local BUTTON_CLICK_CENTER_Y_SCALE = Config.getConstant("ButtonCenterYScale")
local BUTTON_CLICK_REVERSE_TWEEN_INFO =
	TweenInfo.new(BUTTON_CLICK_TWEEN_INFO.Time, BUTTON_CLICK_TWEEN_INFO.EasingStyle, Enum.EasingDirection.Out)

local BUTTON_MOUSE_OVER_TWEEN_INFO = Config.getConstant("ButtonMouseOverTweenInfo")
local BUTTON_MOUSE_OVER_POSITION_OFFSET = Config.getConstant("ButtonMouseOverPositionOffset")
local BUTTON_MOUSE_OVER_SIZE = Config.getConstant("ButtonMouseOverSize")

local BUTTON_ANCHOR_POINT = Vector2.new(0.5, BUTTON_CLICK_CENTER_Y_SCALE)
local BUTTON_DEFAULT_POSITION = UDim2.new(0.5, 0, BUTTON_CLICK_CENTER_Y_SCALE, 0)
local BUTTON_MOUSE_OVER_POSITION = BUTTON_DEFAULT_POSITION + BUTTON_MOUSE_OVER_POSITION_OFFSET

-- public
local function initializeButtonAnimations(GuiButton, Options)
	if not (typeof(GuiButton) == "Instance") then
		error(`{GuiButton} is not an Instance!`)
	end
	if not GuiButton:IsA("GuiButton") then
		error(`{GuiButton} is not a GuiButton!`)
	end

	Options = Options or {}

	if not typeof(Options) == "table" then
		error(`{Options} is not a table!`)
	end

	local ContainerFrame = Instance.new("Frame")
	ContainerFrame.AnchorPoint = GuiButton.AnchorPoint
	ContainerFrame.Position = GuiButton.Position
	ContainerFrame.Size = GuiButton.Size
	ContainerFrame.ZIndex = GuiButton.ZIndex
	ContainerFrame.LayoutOrder = GuiButton.LayoutOrder
	ContainerFrame.Name = GuiButton.Name .. "Container"
	ContainerFrame.Parent = GuiButton.Parent
	ContainerFrame.BackgroundTransparency = 1

	GuiButton.AnchorPoint = BUTTON_ANCHOR_POINT
	GuiButton.Position = BUTTON_DEFAULT_POSITION
	GuiButton.Size = UDim2.new(1, 0, 1, 0)
	GuiButton.Parent = ContainerFrame

	GuiButton.MouseButton1Down:Connect(function()
		TweenService:Create(GuiButton, BUTTON_CLICK_TWEEN_INFO, {
			Size = BUTTON_CLICK_SIZE,
		}):Play()
	end)
	GuiButton.MouseButton1Up:Connect(function()
		TweenService:Create(GuiButton, BUTTON_CLICK_REVERSE_TWEEN_INFO, {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()
	end)

	ContainerFrame.MouseLeave:Connect(function()
		TweenService:Create(GuiButton, BUTTON_CLICK_REVERSE_TWEEN_INFO, {
			Position = BUTTON_DEFAULT_POSITION,
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()
	end)

	if Options.LiftButtonOnMouseOver then
		ContainerFrame.MouseEnter:Connect(function()
			TweenService:Create(GuiButton, BUTTON_MOUSE_OVER_TWEEN_INFO, {
				Position = BUTTON_MOUSE_OVER_POSITION,
				Size = BUTTON_MOUSE_OVER_SIZE,
			}):Play()
		end)
	else
		ContainerFrame.MouseEnter:Connect(function()
			TweenService:Create(GuiButton, BUTTON_MOUSE_OVER_TWEEN_INFO, {
				Size = BUTTON_MOUSE_OVER_SIZE,
			}):Play()
		end)
	end

    -- TODO currently it is possible for you to click a button and it still doesn't register,
    -- because the animation resizes the button and you're no longer hovered over the button

    -- TODO also MouseLeave is not very reliable on xbox and the xbox virtual cursor is really fat
end

return {
	initializeButton = initializeButtonAnimations,
}
