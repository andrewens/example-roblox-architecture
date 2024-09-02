-- public
local function isA(value, className)
	return (typeof(value) == "Instance" or typeof(value) == "table") and value:IsA(className)
end

return {
	isA = isA,
}
