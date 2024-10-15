-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")
local SoccerDuelsClientModule = script:FindFirstAncestor("SoccerDuelsClient")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)

local UIAnimations = require(SoccerDuelsClientModule.UIAnimations)

-- const
local BOOLEAN_SETTING_ON_COLOR3 = Config.getConstant("BooleanSettingOnColor3")
local BOOLEAN_SETTING_OFF_COLOR3 = Config.getConstant("BooleanSettingOffColor3")

-- public / Client class methods
local function newSettingsModal(self)
    -- assets
	local SettingsModalFrame = Assets.getExpectedAsset("SettingsModal", "MainGui", self.MainGui)
	local SettingButtonsContainer =
		Assets.getExpectedAsset("SettingButtonsContainer", "SettingsModal", SettingsModalFrame)
	local SettingsModalCloseButton =
		Assets.getExpectedAsset("SettingsModalCloseButton", "SettingsModal", SettingsModalFrame)
	local BooleanSettingTemplate =
		Assets.cloneExpectedAsset("BooleanSettingTemplate", "SettingButtonsContainer", SettingButtonsContainer)

	-- settings modal frame
	self:OnVisibleModalChangedConnect(function(visibleModalName)
		SettingsModalFrame.Visible = visibleModalName == "Settings"
	end)

	UIAnimations.initializePopup(self, SettingsModalFrame)
	SettingsModalFrame.Visible = false

	-- settings buttons
	for _, SettingButton in SettingButtonsContainer:GetChildren() do
		if not SettingButton:IsA(BooleanSettingTemplate.ClassName) then
			continue
		end

		SettingButton:Destroy()
	end

	for i, Setting in self:GetSettings() do
		local valueType = typeof(Setting.Value)
		local settingName = Setting.Name

		if not (valueType == "boolean") then
			error(`{valueType} type setting buttons are not supported`)
		end

		local SettingButton = BooleanSettingTemplate:Clone()
		SettingButton.Name = Setting.Name
		SettingButton.LayoutOrder = i
		SettingButton.Parent = SettingButtonsContainer

		local SettingNameTextLabel =
			Assets.getExpectedAsset("BooleanSettingTemplateName", "BooleanSettingTemplate", SettingButton)
		local SettingButtonImageButton =
			Assets.getExpectedAsset("BooleanSettingTemplateButton", "BooleanSettingTemplate", SettingButton)

		SettingNameTextLabel.Text = Setting.Name
		SettingButtonImageButton.Activated:Connect(function()
			self:ToggleBooleanSetting(settingName)
		end)

		UIAnimations.initializeButton(self, SettingButtonImageButton)
	end

	self:OnSettingChangedConnect(function(settingName, settingValue)
		-- this assumes every settingValue is boolean

		local SettingButton = SettingButtonsContainer:FindFirstChild(settingName)
		local SettingValueTextLabel =
			Assets.getExpectedAsset("BooleanSettingTemplateValue", "BooleanSettingTemplate", SettingButton)
		local SettingButtonImageButton =
			Assets.getExpectedAsset("BooleanSettingTemplateButton", "BooleanSettingTemplate", SettingButton)

		SettingValueTextLabel.Text = if settingValue then "ON" else "OFF"
		SettingButtonImageButton.ImageColor3 = if settingValue
			then BOOLEAN_SETTING_ON_COLOR3
			else BOOLEAN_SETTING_OFF_COLOR3
	end)

    -- close button
	SettingsModalCloseButton.Activated:Connect(function()
		self:SetVisibleModalName(nil)
	end)

	UIAnimations.initializeButton(self, SettingsModalCloseButton)
end

return {
	new = newSettingsModal,
}
