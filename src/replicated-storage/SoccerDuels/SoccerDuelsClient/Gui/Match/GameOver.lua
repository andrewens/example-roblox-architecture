-- dependency
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)
local Maid = require(SoccerDuelsModule.Maid)

-- public / Client class methods
local function newGameOverGui(self)
	-- gui
	local GameOverGui = Assets.getExpectedAsset("GameOverGui", "MainGui", self.MainGui)
	local GameOverMVPContainer = Assets.getExpectedAsset("GameOverMVPContainer", "GameOverGui", GameOverGui)

	local GameOverMVPUserNameLabel = Assets.getExpectedAsset("GameOverMVPUserNameLabel", "GameOverGui", GameOverGui)
	local GameOverMVPLevelLabel = Assets.getExpectedAsset("GameOverMVPLevelLabel", "GameOverGui", GameOverGui)

	local GameOverMVPGoalsLabel = Assets.getExpectedAsset("GameOverMVPGoalsLabel", "GameOverGui", GameOverGui)
	local GameOverMVPAssistsLabel = Assets.getExpectedAsset("GameOverMVPAssistsLabel", "GameOverGui", GameOverGui)
	local GameOverMVPTacklesLabel = Assets.getExpectedAsset("GameOverMVPTacklesLabel", "GameOverGui", GameOverGui)

	-- var
	local UIMaid = Maid.new()

	-- functions
	local function locallyRenderEndCutscene(MostValuablePlayer)
		local mapName = self:GetConnectedMapName()
		local MapFolder = self:GetConnectedMapFolder()

		local Camera = workspace.Camera
		local EndCutsceneCameraPart =
			Assets.getExpectedAsset(`{mapName} EndCutsceneCameraPart`, `{mapName} MapFolder`, MapFolder)
		local FirstCharacterPositionPart =
			Assets.getExpectedAsset(`{mapName} EndCutsceneCharacterPosition1`, `{mapName} MapFolder`, MapFolder)

		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame =
			CFrame.lookAt(EndCutsceneCameraPart.Position, FirstCharacterPositionPart.Position + Vector3.new(0, 3, 0))

		UIMaid:GiveTask(function()
			Camera.CameraType = Enum.CameraType.Custom
		end)

		local i = if MostValuablePlayer then 2 else 1
		for _, Player in self:GetTeamPlayers() do
			local position = 1
			if Player ~= MostValuablePlayer then
				position = i
				i += 1
			end

			local PositionPart = Assets.getExpectedAsset(
				`{mapName} EndCutsceneCharacterPosition{position}`,
				`{mapName} MapFolder`,
				MapFolder
			)
			local Character = self:ClonePlayerAvatar(Player)

			Character:SetPrimaryPartCFrame(
				CFrame.lookAt(PositionPart.Position + Vector3.new(0, 3, 0), EndCutsceneCameraPart.Position)
			)
			UIMaid:GiveTask(Character)
		end
	end
	local function renderMVPCard(MostValuablePlayer)
		GameOverMVPContainer.Visible = (MostValuablePlayer ~= nil)

		if not GameOverMVPContainer.Visible then
			return
		end

		GameOverMVPUserNameLabel.Text = MostValuablePlayer.Name
		GameOverMVPLevelLabel.Text = self:GetAnyPlayerDataValue("Level", MostValuablePlayer)

		GameOverMVPGoalsLabel.Text = self:GetPlayerLeaderstat(MostValuablePlayer, "Goals")
		GameOverMVPAssistsLabel.Text = self:GetPlayerLeaderstat(MostValuablePlayer, "Assists")
		GameOverMVPTacklesLabel.Text = self:GetPlayerLeaderstat(MostValuablePlayer, "Tackles")
	end

	-- callbacks
	self:OnUserInterfaceModeChangedConnect(function(userInterfaceMode)
		UIMaid:DoCleaning()

		GameOverGui.Visible = (userInterfaceMode == "GameOver")

		if not GameOverGui.Visible then
			return
		end

		local playerTeamIndex = self:GetPlayerTeamIndex(self.Player)
		local MostValuablePlayer = self:GetTeamMVP(playerTeamIndex)

		if playerTeamIndex == nil then
			return
		end

		renderMVPCard(MostValuablePlayer)
		locallyRenderEndCutscene(MostValuablePlayer)
	end)

	GameOverGui.Visible = false
end

return {
	new = newGameOverGui,
}
