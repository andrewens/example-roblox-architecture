-- dependency
local Config = require(script.Config)

-- public
local function getConstant(constantName)
    local value = Config[constantName]
    if value == nil then
        error(`There's no Constant named "{constantName}"`)
    end

    return value
end

return {
    getConstant = getConstant,
}
