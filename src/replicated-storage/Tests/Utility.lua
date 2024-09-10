-- public
local function tableContainsValue(Table, value)
	for k, v in Table do
		if v == value then
			return true
		end
	end

	return false
end
local function tableIsSubsetOfTable(SubsetTable, SupersetTable)
	if typeof(SubsetTable) == "table" and typeof(SupersetTable) == "table" then
		for k, v in SubsetTable do
			local s, msg = tableIsSubsetOfTable(v, SupersetTable[k])
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end

		return true
	end

	if SubsetTable ~= SupersetTable then
		return false, `{SubsetTable} != {SupersetTable}`
	end

	return true
end
local function tableDeepEqual(Table1, Table2)
	if typeof(Table1) == "table" and typeof(Table2) == "table" then
		for k, v in Table1 do
			local s, msg = tableDeepEqual(v, Table2[k])
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end
		for k, v in Table2 do -- redundant, but avoids extra memory
			local s, msg = tableDeepEqual(Table1[k], v)
			if not s then
				return false, msg .. ` (key="{k}")`
			end
		end

		return true
	end

	if Table1 ~= Table2 then
		return false, `{Table1} != {Table2}`
	end

	return true
end

return {
	tableContainsValue = tableContainsValue,
	tableIsSubsetOfTable = tableIsSubsetOfTable,
	tableDeepEqual = tableDeepEqual,
}
