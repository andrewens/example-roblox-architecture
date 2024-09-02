-- dependency
local ExpectedAssets = require(script.ExpectedAssets)

-- public
local function getAsset(assetPath)
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
    getAsset = getAsset,
    getExpectedAssets = getExpectedAssets,
}
