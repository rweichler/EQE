ls = require 'ls'

function getcoefs(presetname)
    local filters
    if presetname then
        filters = eqe.load(presetname, {})
    else
        filters = eqe
    end
    local str = {'return {\n'}
    for i=1,#filters do
        local coefs = {filters[i]:get_coefs(44100)}
        if #coefs > 0 then
            str[#str + 1] = '{'
            for i,v in ipairs(coefs) do
                str[#str + 1] = v..','
            end
            str[#str + 1] = '},\n'
        end
    end
    str[#str + 1] = '}'
    return table.concat(str)
end
