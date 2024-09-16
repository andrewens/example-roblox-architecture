-- dependency
local SoundService = game:GetService("SoundService")

local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Assets = require(SoccerDuelsModule.AssetDependencies)

-- public / Client class methods
local function playSound(self, soundName)
    if not self:GetSetting("Sound Effects") then
        return
    end

    SoundService:PlayLocalSound(
        Assets.getExpectedAsset(soundName)
    )
end

return {
    playSound = playSound,
}
