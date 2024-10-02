-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local ExpectedAssets = require(script.ExpectedAssets)

-- const
local PATH_IGNORE_ATTRIBUTE_NAME = "AssetPathIgnore"

-- public
local function ignoreWrapperInstanceInPath(WrapperInstance, RealInstance)
	--[[
		In UIAnimations, we wrap things like buttons in containers to make the
		animations work while avoiding extra configuration of the templates.

		This breaks asset path behavior -- unless we can treat those wrapper Frames/etc
		as if they're not in the path. Hence this method
	]]

	if not (typeof(WrapperInstance) == "Instance") then
		error(`{WrapperInstance} is not an Instance!`)
	end
	if not (typeof(RealInstance) == "Instance") then
		error(`{RealInstance} is not an Instance!`)
	end
	if not (RealInstance.Parent == WrapperInstance) then
		error(`{RealInstance} is not a child of {WrapperInstance}!`)
	end

	WrapperInstance.Name = RealInstance.Name
	WrapperInstance:SetAttribute(PATH_IGNORE_ATTRIBUTE_NAME, true)
end
local function getAssetByPath(assetPath, RootInstance)
	if RootInstance and RootInstance:GetAttribute(PATH_IGNORE_ATTRIBUTE_NAME) then
		repeat
			RootInstance = RootInstance:FindFirstChild(RootInstance.Name)
			if RootInstance == nil then
				return nil
			end
		until not RootInstance:GetAttribute(PATH_IGNORE_ATTRIBUTE_NAME)
	end

	local ChildNames = string.split(assetPath, "/")
	local Child = RootInstance or game

	for _, childName in ChildNames do
		repeat
			Child = Child:FindFirstChild(childName)
			if Child == nil then
				return nil
			end
		until not Child:GetAttribute(PATH_IGNORE_ATTRIBUTE_NAME)
	end

	return Child
end
local function getExpectedAsset(assetName, rootAssetName, RootInstance)
	if not (typeof(assetName) == "string") then
		error(`{assetName} is not a string!`)
	end

	local AssetJson = ExpectedAssets[assetName]
	if AssetJson == nil then
		error(`There's no ExpectedAsset named "{assetName}"`)
	end

	-- option to get asset from an Instance and not the game
	if rootAssetName then
		if not (typeof(rootAssetName) == "string") then
			error(`{rootAssetName} is not a string!`)
		end
		if not (typeof(RootInstance) == "Instance") then
			error(`{RootInstance} is not an Instance!`)
		end

		local RootAssetJson = ExpectedAssets[rootAssetName]
		if RootAssetJson == nil then
			error(`There's no ExpectedAsset named "{rootAssetName}"`)
		end

		local assetPath = string.gsub(AssetJson.Path, RootAssetJson.Path .. "/", "")
		local AssetInstance = getAssetByPath(assetPath, RootInstance)

		if AssetInstance == nil then
			local Children = RootInstance:GetChildren()
			for i, Child in Children do
				Children[i] = tostring(Child)
			end

			error(
				`Couldn't find "{assetName}" from RootAsset {rootAssetName} "{RootInstance}"; children: {table.concat(Children, ", ")}`
			)
		end

		return AssetInstance
	end

	local AssetInstance = getAssetByPath(AssetJson.Path)
	if AssetInstance == nil then
		error(`Couldn't find Asset "{assetName}" with path "{AssetJson.Path}"`)
	end

	return AssetInstance
end
local function cloneExpectedAsset(assetName, rootAssetName, RootInstance)
	local AssetInstance = getExpectedAsset(assetName, rootAssetName, RootInstance)
	return AssetInstance:Clone()
end
local function getExpectedAssets()
	return ExpectedAssets
end
local function organizeDependenciesServerOnly()
	for _, RbxInstance in StarterGui:GetChildren() do
		RbxInstance.Parent = ReplicatedStorage.UserInterface
	end

	local CharacterGuiTemplate = workspace:FindFirstChild("CharacterGuiTemplate")
	if CharacterGuiTemplate then
		CharacterGuiTemplate.Parent = ReplicatedStorage.UserInterface
	end

	local MapTemplatesFolder = workspace:FindFirstChild("MapTemplates")
	if MapTemplatesFolder then
		MapTemplatesFolder.Parent = ServerStorage
	end
end

return {
	ignoreWrapperInstanceInPath = ignoreWrapperInstanceInPath,
	cloneExpectedAsset = cloneExpectedAsset,

	getAsset = getAssetByPath,
	getExpectedAsset = getExpectedAsset,
	getExpectedAssets = getExpectedAssets,

	organizeDependencies = organizeDependenciesServerOnly,
}
