-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExternalConfigModule = ReplicatedStorage:FindFirstChild("Config")

local Config = require(script.DefaultConfig)

-- var
local ExternalConfig

-- public
local function getConstant(constantName)
	local value = Config[constantName]
	if value == nil then
		error(`There's no Constant named "{constantName}"`)
	end

	return value
end
local function initializeConfig()
	if ExternalConfigModule == nil then
		return
	end

	ExternalConfig = require(ExternalConfigModule)

	for k, v in ExternalConfig do
		if Config[k] == nil then
			continue
		end

		Config[k] = v
        print(k, "=", v)
	end
end

initializeConfig()

return {
	getConstant = getConstant,
    --initialize = initializeConfig,
}
