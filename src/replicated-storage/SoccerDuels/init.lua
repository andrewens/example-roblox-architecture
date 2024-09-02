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
local function initializeSoccerDuels() end

return {
	getAsset = getAsset,
	initialize = initializeSoccerDuels,
}
