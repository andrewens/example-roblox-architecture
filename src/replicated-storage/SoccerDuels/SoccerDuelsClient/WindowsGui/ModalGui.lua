-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Config = require(SoccerDuelsModule.Config)
local Maid = require(SoccerDuelsModule.Maid)

-- const
local BOOLEAN_SETTING_ON_IMAGE_ID = Config.getConstant("BooleanSettingOnImageId")
local BOOLEAN_SETTING_OFF_IMAGE_ID = Config.getConstant("BooleanSettingOffImageId")

-- var
local ModalGuiMetatable

-- private / ModalGui class methods
local function initializeSettingsModal(self)
	local SettingButtonsContainer = Assets.getExpectedAsset("SettingButtonsContainer", "ModalFrames", self._ModalFrames)
	local BooleanSettingTemplate =
		Assets.cloneExpectedAsset("BooleanSettingTemplate", "SettingButtonsContainer", SettingButtonsContainer)
	local SettingsModalCloseButton =
		Assets.getExpectedAsset("SettingsModalCloseButton", "ModalFrames", self._ModalFrames)

	for _, SettingButton in SettingButtonsContainer:GetChildren() do
		if not SettingButton:IsA(BooleanSettingTemplate.ClassName) then
			continue
		end

		SettingButton:Destroy()
	end

	for i, Setting in self._Client:GetSettings() do
		local valueType = typeof(Setting.Value)
		local settingName = Setting.Name

		if not (valueType == "boolean") then
			error(`{valueType} setting buttons are not supported`)
		end

		local SettingButton = BooleanSettingTemplate:Clone()
		SettingButton.Name = Setting.Name
		SettingButton.LayoutOrder = i
		SettingButton.Parent = SettingButtonsContainer

		local SettingNameTextLabel =
			Assets.getExpectedAsset("BooleanSettingTemplateName", "BooleanSettingTemplate", SettingButton)
		SettingNameTextLabel.Text = Setting.Name

		local SettingButtonImageButton =
			Assets.getExpectedAsset("BooleanSettingTemplateButton", "BooleanSettingTemplate", SettingButton)
		SettingButtonImageButton.Activated:Connect(
			function() -- TODO should this be put in showSettingsModal() to save memory?
				self._Client:ToggleBooleanSetting(settingName)
			end
		)
	end

	SettingsModalCloseButton.Activated:Connect(function()
		self._Client:SetVisibleModalName(nil)
	end)
end
local function showSettingsModal(self)
	local SettingButtonsContainer = Assets.getExpectedAsset("SettingButtonsContainer", "ModalFrames", self._ModalFrames)
	self._Maid:GiveTask(self._Client:OnSettingChangedConnect(function(settingName, settingValue)
		-- assuming it's a boolean
		local SettingButton = SettingButtonsContainer:FindFirstChild(settingName)

		local SettingValueTextLabel =
			Assets.getExpectedAsset("BooleanSettingTemplateValue", "BooleanSettingTemplate", SettingButton)
		SettingValueTextLabel.Text = if settingValue then "ON" else "OFF"

		local SettingButtonImageButton =
			Assets.getExpectedAsset("BooleanSettingTemplateButton", "BooleanSettingTemplate", SettingButton)
		SettingButtonImageButton.Image =
			`rbxassetid://{if settingValue then BOOLEAN_SETTING_ON_IMAGE_ID else BOOLEAN_SETTING_OFF_IMAGE_ID}`
	end))
end

-- public / ModalGui class methods
local function hideModalGui(self)
	self._Maid:DoCleaning()
end
local function showModalGui(self, visibleModalName)
	self._Maid:DoCleaning()

	if visibleModalName == nil then
		return
	end

	local VisibleModalFrame = self._ModalFrames:FindFirstChild(visibleModalName)
	if VisibleModalFrame == nil then
		error(`There's no ModalFrame named "{visibleModalName}"`)
	end

	-- make modal frame visible
	VisibleModalFrame.Visible = true
	self._Maid:GiveTask(function()
		VisibleModalFrame.Visible = false
	end)

	if visibleModalName == "Settings" then
		showSettingsModal(self)
	end
end

-- public
local function newModalGui(Client, WindowsGui)
	if WindowsGui == nil then
		error(`WindowsGui is nil!`)
	end

	local self = {}
	self._Client = Client
	self._ModalFrames = Assets.getExpectedAsset("ModalFrames", "WindowsGui", WindowsGui)
	self._Maid = Maid.new()

	setmetatable(self, ModalGuiMetatable)

	initializeSettingsModal(self)

	return self
end
local function initializeModalGui()
	local ModalGuiMethods = {
		Hide = hideModalGui,
		ShowModal = showModalGui,
	}
	ModalGuiMetatable = { __index = ModalGuiMethods }
end

return {
	new = newModalGui,
	initialize = initializeModalGui,
}
