require("util.string")

local function parse_error(err)
  if string.is_non_empty_string(err) then
    local colons = string.split(err, ':')
    table.remove(colons, 1)
    table.remove(colons, 1)
    return string.trim(string.join(colons, ':')) or ''
  end
end


return {
  parse_error = parse_error
}
