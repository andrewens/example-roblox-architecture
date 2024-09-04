-- var
local Enums = {} -- string enumTypeName --> string enumName --> int enumInteger

-- public
local function iterateEnumsOfType(enumTypeName)
    local EnumsOfType = Enums[enumTypeName]
    if EnumsOfType == nil then
        error(`There's no EnumType named "{enumTypeName}"`)
    end

    return ipairs(EnumsOfType)
end
local function enumToName(enumTypeName, enumInteger)
    local EnumsOfType = Enums[enumTypeName]
    if EnumsOfType == nil then
        error(`There's no EnumType named "{enumTypeName}"`)
    end

    return EnumsOfType[enumInteger]
end
local function getEnum(enumTypeName, enumName)
    local EnumsOfType = Enums[enumTypeName]
    if EnumsOfType == nil then
        error(`There's no EnumType named "{enumTypeName}"`)
    end

    return EnumsOfType[enumName]
end
local function initializeEnums()
    for _, EnumModule in script:GetChildren() do
        local EnumsOfType = require(EnumModule)

        for enumInteger, enumName in ipairs(EnumsOfType) do
            EnumsOfType[enumName] = enumInteger
        end

        Enums[EnumModule.Name] = EnumsOfType
    end
end

initializeEnums()

return {
    iterateEnumsOfType = iterateEnumsOfType,
    enumToName = enumToName,
    getEnum = getEnum,
    -- initialize = initializeEnums,
}
