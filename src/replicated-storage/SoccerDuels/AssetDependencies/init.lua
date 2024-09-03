-- dependency
local ExpectedAssets = require(script.ExpectedAssets)

-- public
local function getAssetByPath(assetPath, RootInstance)
	local ChildNames = string.split(assetPath, "/")
	local Child = RootInstance or game

	for _, childName in ChildNames do
		Child = Child:FindFirstChild(childName)
		if Child == nil then
			break
		end
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

		return getAssetByPath(assetPath, RootInstance)
	end

	return getAssetByPath(AssetJson.Path)
end
local function cloneExpectedAsset(assetName, rootAssetName, RootInstance)
	local AssetInstance = getExpectedAsset(assetName, rootAssetName, RootInstance)
	return AssetInstance:Clone()
end
local function getExpectedAssets()
	return ExpectedAssets
end

return {
	cloneExpectedAsset = cloneExpectedAsset,

	getAsset = getAssetByPath,
	getExpectedAsset = getExpectedAsset,
	getExpectedAssets = getExpectedAssets,
}
