---Returns true when the given string str starts with given string start.
---@param str string
---@param start string
---@return boolean
local function starts_with(str, start)
    return str:sub(1, #start) == start
end

---Returns true when the given string str ends with given string ending.
---@param str string
---@param ending string
---@return boolean
local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

---Combines all given tables into one.
---@return table
local function table_assign(result, ...)
    for i, v in ipairs({ ... }) do
        if v ~= nil then
            for k, value in pairs(v) do
                result[k] = value
            end
        end
    end
    return result
end

return {
    starts_with = starts_with,
    ends_with = ends_with,
    table_assign = table_assign
}