-- dependency
local TweenService = game:GetService("TweenService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Utility = require(SoccerDuelsModule.Utility)

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

local COUNTDOWN_TIMER_TEXT_SIZE_GOAL = Config.getConstant("CountdownTimerTextSizeGoal")
local COUNTDOWN_TIMER_LAST_TWEEN_INFO = Config.getConstant("CountdownTimerLastTweenInfo")
local COUNTDOWN_TIMER_FIRST_TWEEN_INFO = Config.getConstant("CountdownTimerFirstTweenInfo")
local COUNTDOWN_TIMER_DURATION_BETWEEN_TWEENS = Config.getConstant("CountdownTimerDurationBetweenTweensSeconds")

local PART_FLASH_TRANSPARENCY = Config.getConstant("FlashingPartTransparency")
local PART_FLASHING_TWEEN_INFO = Config.getConstant("FlashingPartTweenInfo")

local BUFFERING_ANIMATION_SOCCER_BALL_IMAGE = Config.getConstant("BufferingAnimationSoccerBallImage")
local BUFFERING_ANIMATION_MIN_SOCCER_BALL_SIZE = Config.getConstant("BufferingAnimationSoccerBallMinSize")
local BUFFERING_ANIMATION_MAX_SOCCER_BALL_SIZE = Config.getConstant("BufferingAnimationSoccerBallMaxSize")
local BUFFERING_ANIMATION_FIRST_TWEEN_INFO = Config.getConstant("BufferingAnimationFirstTweenInfo")
local BUFFERING_ANIMATION_LAST_TWEEN_INFO = Config.getConstant("BufferingAnimationLastTweenInfo")

local FRAMES_PER_SECOND = 60
local FRAMES_BETWEEN_EACH_SOCCER_BALL_ANIMATION =
	math.ceil(FRAMES_PER_SECOND * Config.getConstant("BufferingAnimationSecondsBetweenEachSoccerBallAnimation"))
local BUFFERING_ANIMATION_FRAMES_RESTING =
	math.ceil(FRAMES_PER_SECOND * Config.getConstant("BufferingAnimationRestDurationSeconds"))
local FRAMES_PER_BUFFERING_ANIMATION_FIRST_TWEEN =
	math.ceil(FRAMES_PER_SECOND * BUFFERING_ANIMATION_FIRST_TWEEN_INFO.Time)
local FRAMES_PER_BUFFERING_ANIMATION_LAST_TWEEN =
	math.ceil(FRAMES_PER_SECOND * BUFFERING_ANIMATION_LAST_TWEEN_INFO.Time)

local MAX_FRAME_INDEX = BUFFERING_ANIMATION_FRAMES_RESTING
	+ FRAMES_PER_BUFFERING_ANIMATION_FIRST_TWEEN
	+ FRAMES_PER_BUFFERING_ANIMATION_LAST_TWEEN
local TWEEN_1_FRAME_INDEX = 0
local TWEEN_2_FRAME_INDEX = FRAMES_BETWEEN_EACH_SOCCER_BALL_ANIMATION
local TWEEN_3_FRAME_INDEX = 2 * FRAMES_BETWEEN_EACH_SOCCER_BALL_ANIMATION
local TWEEN_4_FRAME_INDEX = FRAMES_PER_BUFFERING_ANIMATION_FIRST_TWEEN
local TWEEN_5_FRAME_INDEX = FRAMES_PER_BUFFERING_ANIMATION_FIRST_TWEEN + FRAMES_BETWEEN_EACH_SOCCER_BALL_ANIMATION
local TWEEN_6_FRAME_INDEX = FRAMES_PER_BUFFERING_ANIMATION_FIRST_TWEEN + 2 * FRAMES_BETWEEN_EACH_SOCCER_BALL_ANIMATION

local MAX_SIZE_TWEEN_GOAL = { Size = BUFFERING_ANIMATION_MAX_SOCCER_BALL_SIZE }
local MIN_SIZE_TWEEN_GOAL = { Size = BUFFERING_ANIMATION_MIN_SOCCER_BALL_SIZE }

local SOCCER_BALL_ANIMATION_ICON_NAME = "AnimatedSoccerBall"

-- var
local BufferingImageLabels = {} -- BufferingImage --> true
local frameIndex = 0

-- private
local function wrapGuiObjectInFrame(GuiObject)
	local ContainerFrame = Instance.new("Frame")
	ContainerFrame.AnchorPoint = GuiObject.AnchorPoint
	ContainerFrame.Position = GuiObject.Position
	ContainerFrame.Size = GuiObject.Size
	ContainerFrame.ZIndex = GuiObject.ZIndex
	ContainerFrame.LayoutOrder = GuiObject.LayoutOrder
	ContainerFrame.Parent = GuiObject.Parent
	ContainerFrame.BackgroundTransparency = 1

	GuiObject.AnchorPoint = BUTTON_ANCHOR_POINT
	GuiObject.Position = BUTTON_DEFAULT_POSITION
	GuiObject.Size = UDim2.new(1, 0, 1, 0)
	GuiObject.Parent = ContainerFrame

	Assets.ignoreWrapperInstanceInPath(ContainerFrame, GuiObject)

	return ContainerFrame
end
local function wrapGuiObjectInFramePreservingOriginalSizeValue(GuiObject)
	local ContainerFrame = Instance.new("Frame")
	ContainerFrame.AnchorPoint = Vector2.new(0.5, 1)
	ContainerFrame.Position = UDim2.new(0.5, 0, 1, 0)
	ContainerFrame.Size = UDim2.new(1, 0, 1, 0)
	ContainerFrame.ZIndex = GuiObject.ZIndex
	ContainerFrame.LayoutOrder = GuiObject.LayoutOrder
	ContainerFrame.Parent = GuiObject.Parent
	ContainerFrame.BackgroundTransparency = 1

	GuiObject.Parent = ContainerFrame

	Assets.ignoreWrapperInstanceInPath(ContainerFrame, GuiObject)

	return ContainerFrame
end
local function playSoccerBallAnimationTween(soccerBallIndex, tweenInfo, TweenGoal)
	local imageName = SOCCER_BALL_ANIMATION_ICON_NAME .. tostring(soccerBallIndex)
	for BufferingImage, _ in BufferingImageLabels do
		if BufferingImage.Parent == nil then
			BufferingImageLabels[BufferingImage] = nil
			continue
		end

		TweenService:Create(BufferingImage[imageName], tweenInfo, TweenGoal):Play()
	end
end
local function runBufferingAnimations(dt)
	frameIndex = (frameIndex + 1) % MAX_FRAME_INDEX

	if next(BufferingImageLabels) == nil then
		return
	end

	if frameIndex == TWEEN_1_FRAME_INDEX then
		playSoccerBallAnimationTween(1, BUFFERING_ANIMATION_FIRST_TWEEN_INFO, MAX_SIZE_TWEEN_GOAL)
	elseif frameIndex == TWEEN_2_FRAME_INDEX then
		playSoccerBallAnimationTween(2, BUFFERING_ANIMATION_FIRST_TWEEN_INFO, MAX_SIZE_TWEEN_GOAL)
	elseif frameIndex == TWEEN_3_FRAME_INDEX then
		playSoccerBallAnimationTween(3, BUFFERING_ANIMATION_FIRST_TWEEN_INFO, MAX_SIZE_TWEEN_GOAL)
	elseif frameIndex == TWEEN_4_FRAME_INDEX then
		playSoccerBallAnimationTween(1, BUFFERING_ANIMATION_LAST_TWEEN_INFO, MIN_SIZE_TWEEN_GOAL)
	elseif frameIndex == TWEEN_5_FRAME_INDEX then
		playSoccerBallAnimationTween(2, BUFFERING_ANIMATION_LAST_TWEEN_INFO, MIN_SIZE_TWEEN_GOAL)
	elseif frameIndex == TWEEN_6_FRAME_INDEX then
		playSoccerBallAnimationTween(3, BUFFERING_ANIMATION_LAST_TWEEN_INFO, MIN_SIZE_TWEEN_GOAL)
	end
end

-- public / Client class methods
local function initializeBufferingAnimation(self, BufferingImage)
	if not (typeof(BufferingImage) == "Instance") then
		error(`{BufferingImage} is not an Instance!`)
	end
	if not (BufferingImage:IsA("GuiObject")) then
		error(`{BufferingImage} is not a GuiObject!`)
	end

	if BufferingImage:IsA("ImageLabel") or BufferingImage:IsA("ImageButton") then
		BufferingImage.ImageTransparency = 1
	end

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.Padding = UDim.new(0.01, 0)
	UIListLayout.Parent = BufferingImage

	local SoccerBall1 = Instance.new("ImageLabel")
	SoccerBall1.Image = BUFFERING_ANIMATION_SOCCER_BALL_IMAGE
	SoccerBall1.Size = BUFFERING_ANIMATION_MIN_SOCCER_BALL_SIZE
	SoccerBall1.BackgroundTransparency = 1

	local UIAspectRatio = Instance.new("UIAspectRatioConstraint")
	UIAspectRatio.AspectRatio = 1
	UIAspectRatio.Parent = SoccerBall1

	local SoccerBall2 = SoccerBall1:Clone()
	local SoccerBall3 = SoccerBall1:Clone()

	SoccerBall1.LayoutOrder = 1
	SoccerBall2.LayoutOrder = 2
	SoccerBall3.LayoutOrder = 3

	SoccerBall1.Name = SOCCER_BALL_ANIMATION_ICON_NAME .. '1'
	SoccerBall2.Name = SOCCER_BALL_ANIMATION_ICON_NAME .. '2'
	SoccerBall3.Name = SOCCER_BALL_ANIMATION_ICON_NAME .. '3'

	SoccerBall1.Parent = BufferingImage
	SoccerBall2.Parent = BufferingImage
	SoccerBall3.Parent = BufferingImage

	BufferingImageLabels[BufferingImage] = true
end
local function destroyBufferingAnimation(self, BufferingImage)
	if BufferingImageLabels[BufferingImage] == nil then
		return
	end

	BufferingImageLabels[BufferingImage] = nil

	for _, SoccerBallIcon in BufferingImage:GetChildren() do
		if string.find(SoccerBallIcon.Name, SOCCER_BALL_ANIMATION_ICON_NAME) == nil then
			continue
		end

		SoccerBallIcon:Destroy()
	end
end

local function flashNeonPart(self, Part)
	if not (typeof(Part) == "Instance" and Part:IsA("BasePart")) then
		error(`{Part} is not a BasePart!`)
	end

	Part.Transparency = PART_FLASH_TRANSPARENCY

	TweenService:Create(Part, PART_FLASHING_TWEEN_INFO, {
		Transparency = 1,
	}):Play()
end

local function initializeCountdownTimerAnimations(self, TextLabel)
	if not (typeof(TextLabel) == "Instance") then
		error(`{TextLabel} is not an Instance!`)
	end
	if not (TextLabel:IsA("TextLabel")) then
		error(`{TextLabel} is not a TextLabel!`)
	end

	local ContainerFrame = wrapGuiObjectInFrame(TextLabel)

	TextLabel:GetPropertyChangedSignal("Text"):Connect(function()
		TweenService:Create(TextLabel, COUNTDOWN_TIMER_FIRST_TWEEN_INFO, {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()

		task.wait(COUNTDOWN_TIMER_DURATION_BETWEEN_TWEENS)

		TweenService:Create(TextLabel, COUNTDOWN_TIMER_LAST_TWEEN_INFO, {
			Size = COUNTDOWN_TIMER_TEXT_SIZE_GOAL,
		}):Play()
	end)
end
local function initializePopupVisibilityAnimations(self, GuiObject)
	if not (typeof(GuiObject) == "Instance") then
		error(`{GuiObject} is not an Instance!`)
	end
	if not (GuiObject:IsA("GuiObject")) then
		error(`{GuiObject} is not a GuiObject!`)
	end

	local ContainerFrame = wrapGuiObjectInFramePreservingOriginalSizeValue(GuiObject)

	local defaultSize = ContainerFrame.Size
	local defaultPosition = ContainerFrame.Position

	local startPosition = defaultPosition + POPUP_START_POSITION_OFFSET
	local startSize = UDim2.new(
		POPUP_START_SIZE_RATIO * defaultSize.X.Scale,
		POPUP_START_SIZE_RATIO * defaultSize.X.Offset,
		POPUP_START_SIZE_RATIO * defaultSize.Y.Scale,
		POPUP_START_SIZE_RATIO * defaultSize.Y.Offset
	)

	GuiObject:GetPropertyChangedSignal("Visible"):Connect(function()
		if not GuiObject.Visible then
			return
		end

		ContainerFrame.Size = startSize
		ContainerFrame.Position = startPosition

		TweenService:Create(ContainerFrame, POPUP_VISIBLE_TWEEN_INFO, {
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

	local ContainerFrame = wrapGuiObjectInFrame(GuiButton)

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
local function initializeUIAnimationsModule(self)
	self._Maid:GiveTask(Utility.runServiceRenderSteppedConnect(runBufferingAnimations))
end

return {
	flashNeonPart = flashNeonPart,

	initializeBufferingAnimation = initializeBufferingAnimation,
	destroyBufferingAnimation = destroyBufferingAnimation,

	initializeTimer = initializeCountdownTimerAnimations,
	initializePopup = initializePopupVisibilityAnimations,
	initializeButton = initializeButtonAnimations,

	initialize = initializeUIAnimationsModule,
}
