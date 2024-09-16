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

-- public
local function initializeButtonAnimations(GuiButton)
    if not (typeof(GuiButton) == "Instance") then
        error(`{GuiButton} is not an Instance!`)
    end
    if not GuiButton:IsA("GuiButton") then
        error(`{GuiButton} is not a GuiButton!`)
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

	GuiButton.AnchorPoint = Vector2.new(0.5, BUTTON_CLICK_CENTER_Y_SCALE)
	GuiButton.Position = UDim2.new(0.5, 0, BUTTON_CLICK_CENTER_Y_SCALE, 0)
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
    GuiButton.MouseLeave:Connect(function()
        TweenService:Create(GuiButton, BUTTON_CLICK_REVERSE_TWEEN_INFO, {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()
    end)
end

return {
	initializeButton = initializeButtonAnimations,
}
