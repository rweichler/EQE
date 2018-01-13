local conv = {}

local function serialize(v, indent)
    return conv[type(v)](v, indent)
end


conv.string = function(s)
    return '[['..string.gsub(s, '%]%]', "]]..']]'..[[")..']]'
end
conv.boolean = tostring
conv['nil'] = tostring
conv.number = tostring

local TAB = '    '

conv.table = function(t, indent)
    indent = indent or 0
    local s = {}
    for k,v in pairs(t) do
        table.insert(s, '[ '..serialize(k)..' ] = '..serialize(v, indent + 1)..',')
    end

    local indent_str = ''
    for i=1,indent do
        indent_str = indent_str..TAB
    end
    s = table.concat(s, '\n'..indent_str..TAB)
    return '{\n'..indent_str..TAB..s..'\n'..indent_str..'}'
end

return serialize
