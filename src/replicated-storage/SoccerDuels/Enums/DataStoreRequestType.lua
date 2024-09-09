return {
	-- these enums' values have to match with roblox's Enum.DataStoreRequestType*
	-- https://create.roblox.com/docs/reference/engine/enums/DataStoreRequestType
	--
	-- * but these enums will be the roblox equivalent enum + 1 because ipairs doesn't work with an index of 0 -_-

	[1] = "Load",
	[2] = "Save",
}
