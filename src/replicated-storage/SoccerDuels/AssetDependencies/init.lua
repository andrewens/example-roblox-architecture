-- dependency
local ExpectedAssets = require(script.ExpectedAssets)

-- protected (use inside of SoccerDuels moduel only)
local getAssetByPath
local function getExpectedAsset(assetName)
    local AssetJson = ExpectedAssets[assetName]
    if AssetJson == nil then
        error(`There's no ExpectedAsset named "{assetName}"`)
    end

    return getAssetByPath(AssetJson.Path)
end

-- public
function getAssetByPath(assetPath)
	local ChildNames = string.split(assetPath, "/")
	local Child = game

	for _, childName in ChildNames do
		Child = Child:FindFirstChild(childName)
		if Child == nil then
			break
		end
	end

	return Child
end
local function getExpectedAssets()
    return ExpectedAssets
end

return {
    -- protected
    getExpectedAsset = getExpectedAsset,

    -- public
    getAsset = getAssetByPath,
    getExpectedAssets = getExpectedAssets,
}
