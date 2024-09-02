-- var
local MockInstances = {}

-- public
local function newMockInstance(mockInstanceClassName)
	local mockInstanceConstructor = MockInstances[mockInstanceClassName]
	if mockInstanceConstructor == nil then
		error(`There is no MockInstance named "{mockInstanceClassName}"`)
	end

	return mockInstanceConstructor()
end
local function initializeMockInstances()
	for _, MockInstanceModule in script:GetChildren() do
		MockInstances[MockInstanceModule.Name] = require(MockInstanceModule)
	end
end

return {
	new = newMockInstance,
	initialize = initializeMockInstances,
}
