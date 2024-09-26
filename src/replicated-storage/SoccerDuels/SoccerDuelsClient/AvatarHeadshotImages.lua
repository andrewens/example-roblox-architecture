-- dependency
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoccerDuelsModule = script:FindFirstAncestor("SoccerDuels")

local Config = require(SoccerDuelsModule.Config)
local Network = require(SoccerDuelsModule.Network)
local Utility = require(SoccerDuelsModule.Utility)

-- const
local THUMBNAIL_TYPE = Config.getConstant("AvatarHeadshotImageThumbnailType")
local THUMBNAIL_SIZE = Config.getConstant("AvatarHeadshotImageThumbnailResolution")
local PLACEHOLDER_IMAGE = Config.getConstant("AvatarHeadshotPlaceholderImage")

-- private
local function getUserIdFromPlayer(Player)
	if Player.UserId >= 0 then
		return Player.UserId
	end

	return 9792010
end
local function getUserThumbnailAsync(userId)
	if RunService:IsServer() then -- don't use async calls in tests to avoid slowing them down
		return PLACEHOLDER_IMAGE, true
	end

	return Players:GetUserThumbnailAsync(userId, THUMBNAIL_TYPE, THUMBNAIL_SIZE)
end

-- protected / Network methods
local function clearCachedAvatarPlayerImage(self, Player)
	if Utility.shouldIgnoreMockPlayerFromServerTests(Player) then
		return
	end

	local userId = getUserIdFromPlayer(Player)

	self._CachedPlayerAvatarImages[userId] = nil
	if self._ImageLabelsWaitingForAvatarImages[userId] then
		self._ImageLabelsWaitingForAvatarImages[userId] = nil
	end
end
local function cachePlayerAvatarImage(self, Player)
	if Utility.shouldIgnoreMockPlayerFromServerTests(Player) then
		return
	end

	local userId = getUserIdFromPlayer(Player)
	if self._CachedPlayerAvatarImages[userId] then
		return
	end

	local imageContent, ready = getUserThumbnailAsync(userId)
	if not (ready and imageContent) then
		return -- ??? documentation wasn't super clear on how this works
	end

	self._CachedPlayerAvatarImages[userId] = imageContent

    if RunService:IsClient() then
	    task.spawn(ContentProvider.PreloadAsync, ContentProvider, { imageContent })
    end

	local ImageLabelsWaiting = self._ImageLabelsWaitingForAvatarImages[userId]
	if ImageLabelsWaiting == nil then
		return
	end

	for _, ImageLabel in ImageLabelsWaiting do
		ImageLabel.Image = imageContent
	end

	self._ImageLabelsWaitingForAvatarImages[userId] = nil
end

-- public / Client class methods
local function setImageLabelImageToAvatarHeadshot(self, ImageLabel, Player)
	if not (typeof(ImageLabel) == "Instance" and (ImageLabel:IsA("ImageLabel") or ImageLabel:IsA("ImageButton"))) then
		error(`{ImageLabel} is not an ImageLabel!`)
	end
	if not Utility.isA(Player, "Player") then
		error(`{Player} is not a Player!`)
	end

	if not RunService:IsClient() then -- avoid invoking any async calls because it slows down server tests!
		ImageLabel.Image = PLACEHOLDER_IMAGE
		return
	end

	local userId = getUserIdFromPlayer(Player)
	local imageContent = self._CachedPlayerAvatarImages[userId]

	if imageContent then
		ImageLabel.Image = imageContent
		return
	end

	ImageLabel.Image = PLACEHOLDER_IMAGE

	if self._ImageLabelsWaitingForAvatarImages[userId] == nil then
		self._ImageLabelsWaitingForAvatarImages[userId] = {}
	end

	table.insert(self._ImageLabelsWaitingForAvatarImages[userId], ImageLabel)

	cachePlayerAvatarImage(self, Player)
end
local function initializeAvatarHeadshotImages(self)
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerConnected", self.Player, function(...)
		cachePlayerAvatarImage(self, ...)
	end))
	self._Maid:GiveTask(Network.onClientEventConnect("PlayerDisconnected", self.Player, function(...)
		clearCachedAvatarPlayerImage(self, ...)
	end))
end

return {
	setImageLabelImageToAvatarHeadshot = setImageLabelImageToAvatarHeadshot,
	initialize = initializeAvatarHeadshotImages,
}
