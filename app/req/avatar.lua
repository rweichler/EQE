local avatars = {}
local function lmfao(k, v)
    local callbacks = avatars[k]
    if v == nil then
        avatars[k] = false
    else
        avatars[k] = v
    end
    for _,f in ipairs(callbacks) do
        f(v)
    end
end
return function(username, cb, size)
    username = username..(size or '-100')
    local v = avatars[username]
    if not(v == nil) then
        if type(v) == 'table' then
            table.insert(avatars[username], cb)
        elseif v == false then
            cb(nil, true)
        else
            cb(v, true)
        end
        return
    end

    avatars[username] = {cb}

    HTTP(BASE_URL..'/res/dynamic/avatar/'..username..'.png', {convert = 'image'}, function(img, status, headers)
        if not(img and status == 200) then
            print('got bad avatar', status)
            lmfao(username, nil)
        else
            lmfao(username, img:retain())
        end
    end)
end
