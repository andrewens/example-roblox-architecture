-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExternalConfigModule = ReplicatedStorage:FindFirstChild("Config")

local Config = require(script.DefaultConfig)

-- var
local ExternalConfig

-- public
local function getConstant(...)
	local Path = { ... }
	local value = Config

	for _, key in Path do
		value = value[key]
		if value == nil then
			error(`There's no Constant with path: Config/{table.concat(Path, "/")}`)
		end
	end

	return value
end
local function initializeConfig()
	if ExternalConfigModule == nil then
		return
	end

	local s, output = pcall(require, ExternalConfigModule)
	if not s then
		warn(`External Config module compiled with syntax error:\n"{output}"\n{debug.traceback()}`)
		return
	end

	ExternalConfig = output
	for k, v in ExternalConfig do
		if Config[k] == nil then
			continue
		end

		Config[k] = v
	end
end

initializeConfig()

return {
	getConstant = getConstant,
	--initialize = initializeConfig,
}
