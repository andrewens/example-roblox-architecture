-- dependency
local TweenService = game:GetService("TweenService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Sounds = require(SoccerDuelsClientModule.Sounds)

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

local POPUP_VISIBLE_TWEEN_INFO = Config.getConstant("PopupVisibleTweenInfo")
local POPUP_START_POSITION_OFFSET = Config.getConstant("PopupStartPositionOffset")
local POPUP_START_SIZE_RATIO = Config.getConstant("PopupStartSizeRatio")

local PART_FLASH_TRANSPARENCY = Config.getConstant("FlashingPartTransparency")
local PART_FLASHING_TWEEN_INFO = Config.getConstant("FlashingPartTweenInfo")

-- public / Client class methods
local function flashNeonPart(self, Part)
	if not (typeof(Part) == "Instance" and Part:IsA("BasePart")) then
		error(`{Part} is not a BasePart!`)
	end

	Part.Transparency = PART_FLASH_TRANSPARENCY

	TweenService:Create(Part, PART_FLASHING_TWEEN_INFO, {
		Transparency = 1,
	}):Play()
end
local function initializePopupVisibilityAnimations(self, Frame)
	if not (typeof(Frame) == "Instance") then
		error(`{Frame} is not an Instance!`)
	end
	if not (Frame:IsA("GuiObject")) then
		error(`{Frame} is not a GuiObject!`)
	end

	local defaultSize = Frame.Size
	local defaultPosition = Frame.Position

	local startPosition = defaultPosition + POPUP_START_POSITION_OFFSET
	local startSize = UDim2.new(
		POPUP_START_SIZE_RATIO * defaultSize.X.Scale,
		POPUP_START_SIZE_RATIO * defaultSize.X.Offset,
		POPUP_START_SIZE_RATIO * defaultSize.Y.Scale,
		POPUP_START_SIZE_RATIO * defaultSize.Y.Offset
	)

	Frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not Frame.Visible then
			return
		end

		Frame.Size = startSize
		Frame.Position = startPosition

		TweenService:Create(Frame, POPUP_VISIBLE_TWEEN_INFO, {
			Size = defaultSize,
			Position = defaultPosition,
		}):Play()
	end)
end
local function initializeButtonAnimations(self, GuiButton, Options)
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
	ContainerFrame.Parent = GuiButton.Parent
	ContainerFrame.BackgroundTransparency = 1

	GuiButton.AnchorPoint = BUTTON_ANCHOR_POINT
	GuiButton.Position = BUTTON_DEFAULT_POSITION
	GuiButton.Size = UDim2.new(1, 0, 1, 0)
	GuiButton.Parent = ContainerFrame

	Assets.ignoreWrapperInstanceInPath(ContainerFrame, GuiButton)

	GuiButton.MouseButton1Down:Connect(function()
		Sounds.playSound(self, "ButtonClickSound")

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
			Sounds.playSound(self, "ButtonMouseEnterSound")

			TweenService:Create(GuiButton, BUTTON_MOUSE_OVER_TWEEN_INFO, {
				Position = BUTTON_MOUSE_OVER_POSITION,
				Size = BUTTON_MOUSE_OVER_SIZE,
			}):Play()
		end)
	else
		ContainerFrame.MouseEnter:Connect(function()
			Sounds.playSound(self, "ButtonMouseEnterSound")

			TweenService:Create(GuiButton, BUTTON_MOUSE_OVER_TWEEN_INFO, {
				Size = BUTTON_MOUSE_OVER_SIZE,
			}):Play()
		end)

		-- (duplicate code is because it will take less memory this way)
	end

	-- TODO currently it is possible for you to click a button and it still doesn't register,
	-- because the animation resizes the button and you're no longer hovered over the button

	-- TODO also MouseLeave is not very reliable on xbox and the xbox virtual cursor is really fat
end

return {
	initializePopup = initializePopupVisibilityAnimations,
	initializeButton = initializeButtonAnimations,
	flashNeonPart = flashNeonPart,
}
