-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- public
local function moveStarterGuiToReplicatedStorage()
	for _, RbxInstance in StarterGui:GetChildren() do
        RbxInstance.Parent = ReplicatedStorage.UserInterface
    end
end
local function isA(value, className)
	return (typeof(value) == "Instance" or typeof(value) == "table") and value:IsA(className)
end

return {
	moveStarterGuiToReplicatedStorage = moveStarterGuiToReplicatedStorage,
	isA = isA,
}
