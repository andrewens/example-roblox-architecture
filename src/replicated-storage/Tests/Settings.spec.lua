-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestsFolder = script:FindFirstAncestor("Tests")

local MockInstance = require(ReplicatedStorage.MockInstance)
local SoccerDuels = require(ReplicatedStorage.SoccerDuels)
local Utility = require(TestsFolder.Utility)

-- test
return function()
	describe("ClientSettings", function()
		describe("Client:GetSettings()", function()
			it("Returns a JSON-compatible array of setting objects", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)
				local ClientSettings = Client:GetSettings()

				assert(typeof(ClientSettings) == "table")

				local DefaultClientSettings = SoccerDuels.getConstant("DefaultClientSettings")
				local ClientSettingsDisplayOrder = SoccerDuels.getConstant("ClientSettingsDisplayOrder")

				for i, Setting in ClientSettings do
					assert(typeof(Setting) == "table")
					assert(Setting.Name == ClientSettingsDisplayOrder[i])
					assert(Setting.Value == DefaultClientSettings[Setting.Name])
				end

				Client:Destroy()
			end)
		end)
		describe("Client:OnSettingChangedConnect()", function()
			it("Immediately invokes a callback for every setting, in order", function()
				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)
				local ClientSettings = Client:GetSettings()

				local i = 0
				local conn = Client:OnSettingChangedConnect(function(settingName, settingValue)
					i += 1
					local CorrectSettingObject = ClientSettings[i]

					assert(CorrectSettingObject.Name == settingName)
					assert(CorrectSettingObject.Value == settingValue)
				end)

				assert(i == #ClientSettings)

				Client:Destroy()
			end)
			it("Invokes callback when a setting is changed, until it's been disconnected", function()
				SoccerDuels.resetTestingVariables()

				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)
				Client:LoadPlayerDataAsync()

				local changeCount = 0
				local lastSettingName, lastSettingValue
				local conn = Client:OnSettingChangedConnect(function(...)
					changeCount += 1
					lastSettingName, lastSettingValue = ...
				end)

				changeCount = 0

				Client:ChangeSetting("Low Graphics", false)

				assert(changeCount == 1)
				assert(lastSettingName == "Low Graphics")
				assert(lastSettingValue == false)

				Client:ChangeSetting("Low Graphics", true)

				assert(changeCount == 2)
				assert(lastSettingName == "Low Graphics")
				assert(lastSettingValue == true)

				conn:Disconnect()
				Client:ChangeSetting("Low Graphics", false)

				assert(changeCount == 2)
				assert(lastSettingName == "Low Graphics")
				assert(lastSettingValue == true)

				Client:Destroy()
			end)
		end)
		describe("Client:ChangeSetting()", function()
			it("Updates the server's cache of Player SaveData", function()
				SoccerDuels.resetTestingVariables()

				local MockPlayer = MockInstance.new("Player")
				local Client = SoccerDuels.newClient(MockPlayer)

				Client:LoadPlayerDataAsync()

				local clientLowGraphicsSetting = Client:GetSetting("Low Graphics")

				Client:ToggleBooleanSetting("Low Graphics")

				assert((not clientLowGraphicsSetting) == Client:GetSetting("Low Graphics"))

				local ServerCachedPlayerData = SoccerDuels.getCachedPlayerSaveData(MockPlayer)
				local ClientCachedPlayerData = Client:GetPlayerSaveData()

				assert(Utility.tableDeepEqual(ServerCachedPlayerData, ClientCachedPlayerData))

				Client:Destroy()
			end)
		end)
	end)
end
