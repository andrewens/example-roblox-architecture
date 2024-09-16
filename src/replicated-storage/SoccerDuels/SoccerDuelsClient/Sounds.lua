-- dependency
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function playSound(self, soundName)
	if not (typeof(soundName) == "string") then
		error(`{soundName} is not a string!`)
	end

	if not RunService:IsClient() then
		return
	end

	if not self:GetSetting("Sound Effects") then
		return
	end

	SoundService:PlayLocalSound(Assets.getExpectedAsset(soundName))
end

return {
	playSound = playSound,
}
