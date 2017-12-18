local cmark = require 'cmark'

local function dl_image(rtf, url, cb)
    HTTP(url, {convert = 'image'}, function(img, status, headers)
        if not(img and status == 200) then return end
        cb(rtf, img:retain())
    end)
end

local rtf = {}
local mt = {
    __index = rtf,
    __concat = function(a, b)
        if type(a) == 'string' then
            return rtf.new(a):append(b)
        elseif type(b) == 'string' then
            return a:append(rtf.new(b))
        else
            return a:append(b)
        end
    end,
}
function rtf.new(s)
    local self = setmetatable({}, mt)
    if s then
        self.m = objc.NSMutableAttributedString:alloc():initWithString(s)
    else
        self.m = objc.NSMutableAttributedString:alloc():init()
    end
    self.attr = {}
    return self
end

function rtf:append(other, idx)
    for i,v in ipairs(other.attr) do
        v.pos = v.pos + self.m:length()
        table.insert(self.attr, v)
    end
    table.sort(self.attr, function(a, b)
        return a.pos < b.pos
    end)
    if idx then
        self.m:insertAttributedString_atIndex(other.m, idx)
    else
        self.m:appendAttributedString(other.m)
    end
    other.m:release()
    other.m = nil
    return self
end

local function is_youtube(s)
    return string.find(s, 'https%:%/%/youtube%.com%/watch%?')
        or string.find(s, 'https%:%/%/www%.youtube%.com%/watch%?')
        or string.find(s, 'https%:%/%/youtu%.be%/')
        or string.find(s, 'https%:%/%/www%.youtu%.be%/')
end

local FONT_NORMAL = 0
local FONT_BOLD = 1
local FONT_ITALIC = 2
local FONT_CODE = 4
local FONT_H1 = 8
local FONT_H2 = 16
local FONT_H3 = 32
local FONT_H4 = 64
local FONT_SUPER = 128
local fonts = {}
do
    local function add(face, size, ...)
        local k = bit.bor(...)
        if fonts[k] then error('font already exists') end
        fonts[k] = objc.UIFont:fontWithName_size(face, size):retain()
    end
    local siz = 13.5
    local h1 = 28
    local h2 = 24
    local h3 = 20
    local h4 = 17

    -- normal
    add('HelveticaNeue-Light', siz, FONT_NORMAL)
    add('HelveticaNeue-Bold', siz, FONT_BOLD)
    add('HelveticaNeue-LightItalic', siz, FONT_ITALIC)
    add('HelveticaNeue-BoldItalic', siz, FONT_BOLD, FONT_ITALIC)

    -- code
    add('CourierNewPSMT', siz, FONT_CODE)
    add('CourierNewPS-BoldMT', siz, FONT_CODE, FONT_BOLD)
    add('CourierNewPS-ItalicMT', siz, FONT_CODE, FONT_ITALIC)
    add('CourierNewPS-BoldItalicMT', siz, FONT_CODE, FONT_BOLD, FONT_ITALIC)

    -- h1
    add('HelveticaNeue-Light', h1, FONT_H1)
    add('HelveticaNeue-Bold', h1, FONT_H1, FONT_BOLD)
    add('HelveticaNeue-LightItalic', h1, FONT_H1, FONT_ITALIC)
    add('HelveticaNeue-BoldItalic', h1, FONT_H1, FONT_BOLD, FONT_ITALIC)

    -- h1 code
    add('CourierNewPSMT', h1, FONT_H1, FONT_CODE)
    add('CourierNewPS-BoldMT', h1, FONT_H1, FONT_CODE, FONT_BOLD)
    add('CourierNewPS-ItalicMT', h1, FONT_H1, FONT_CODE, FONT_ITALIC)
    add('CourierNewPS-BoldItalicMT', h1, FONT_H1, FONT_CODE, FONT_BOLD, FONT_ITALIC)

    -- h2
    add('HelveticaNeue-Light', h2, FONT_H2)
    add('HelveticaNeue-Bold', h2, FONT_H2, FONT_BOLD)
    add('HelveticaNeue-LightItalic', h2, FONT_H2, FONT_ITALIC)
    add('HelveticaNeue-BoldItalic', h2, FONT_H2, FONT_BOLD, FONT_ITALIC)

    -- h2 code
    add('CourierNewPSMT', h2, FONT_H2, FONT_CODE)
    add('CourierNewPS-BoldMT', h2, FONT_H2, FONT_CODE, FONT_BOLD)
    add('CourierNewPS-ItalicMT', h2, FONT_H2, FONT_CODE, FONT_ITALIC)
    add('CourierNewPS-BoldItalicMT', h2, FONT_H2, FONT_CODE, FONT_BOLD, FONT_ITALIC)
end


local parsers = {}

local function parse(md, last)
    local f = parsers[tonumber(md:get_type())]
    if f then
        return f(md, last and md:next() == ffi.NULL)
    else
        return rtf.new('<IDK>')
    end
end

local function add_font(s, font, pos, length)
    pos = pos or 0
    length = length or s.m:length()

    local to_add = {}
    local added = false
    for i,v in ipairs(s.attr) do
        if v.pos >= pos + length then break end
        if v.type == 'font' then
            if pos == v.pos and length == v.length then
                v.font = bit.bor(v.font, font)
                added = true
                break
            elseif pos < v.pos + v.length then
                v.font = bit.bor(v.font, font)
                if pos == v.pos then
                    pos = pos + v.length
                    length = length - v.length
                elseif pos + length == v.pos + v.length then
                    length = length - v.length
                else
                    local left =  {
                        pos = pos,
                        length = v.pos - pos,
                    }
                    table.insert(to_add, left)
                    pos = v.pos + v.length
                    length = length - left.length - v.length
                    if length == 0 then
                        added = true
                        break
                    end
                end
            end
        end
    end
    for i,v in ipairs(to_add) do
        table.insert(s.attr, {
            type = 'font',
            font = font,
            pos = v.pos,
            length = v.length,
        })
    end
    if not added then
        table.insert(s.attr, {
            type = 'font',
            font = font,
            pos = pos,
            length = length,
        })
    end
    table.sort(s.attr, function(a, b)
        return a.pos < b.pos
    end)
end

local function add_attr(s, attr)
    attr.pos = attr.pos or 0
    attr.length = attr.length or s.m:length()
    table.insert(s.attr, attr)
    table.sort(s.attr, function(a, b)
        return a.pos < b.pos
    end)
end

parsers[cmark.NODE_DOCUMENT] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    return s
end

local function get_first(...)
    local t = {...}
    local min
    for i=1,#t do
        local v = t[i]
        if not(v == ffi.NULL) and (not min or v < min) then
            min = v
        end
    end
    return min
end

local nospace = {}
for i=string.byte('a'),string.byte('z') do
    nospace[i] = true
end
for i=string.byte('A'),string.byte('Z') do
    nospace[i] = true
end
for i=string.byte('0'),string.byte('0') do
    nospace[i] = true
end

parsers[cmark.NODE_TEXT] = function(md)
    local cstr = cmark.lib.cmark_node_get_literal(md)

    local s = rtf.new(ffi.string(cstr))

    -- autolinks
    local buf = cstr
    while true do
        local http = get_first(
            C.strstr(buf, 'http://'),
            C.strstr(buf, 'https://')
        )

        if not http then break end

        if not(http == cstr or not nospace[http[-1]]) then
            buf = http + 1
        else

            local space = get_first(
                C.strstr(http, ' '),
                C.strstr(http, '\r'),
                C.strstr(http, '\n'),
                C.strstr(http, '\t')
            )

            local pos = http - cstr
            local length = space and space - http or C.strlen(http)
            local url = ffi.string(http, length)

            add_attr(s, {
                type = 'link',
                url = url,
                pos = pos,
                length = length,
            })

            if not space then
                break
            else
                buf = space + 1
            end
        end
    end

    return s
end

parsers[cmark.NODE_CODE] = function(md)
    local s = rtf.new(md:get_literal())
    add_font(s, FONT_CODE)
    return s
end

parsers[cmark.NODE_CODE_BLOCK] = function(md, last)
    local s = parsers[cmark.NODE_CODE](md)
    return last and s or s..'\n'
end

parsers[cmark.NODE_SOFTBREAK] = function(md)
    return rtf.new(' ')
end

parsers[cmark.NODE_PARAGRAPH] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    return last and s or s..'\n\n'
end
parsers[cmark.NODE_LIST] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    return last and s or s..'\n'
end

parsers[cmark.NODE_STRONG] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    add_font(s, FONT_BOLD)
    return s
end

parsers[cmark.NODE_EMPH] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    add_font(s, FONT_ITALIC)
    return s
end

parsers[cmark.NODE_HEADING] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    local level = md:get_heading_level()
    if level == 1 then
        add_font(s, FONT_H1)
    elseif level == 2 then
        add_font(s, FONT_H2)
    elseif level == 3 then
        add_font(s, FONT_H3)
    else
        add_font(s, FONT_H4)
    end
    return last and s or s..'\n\n'
end

parsers[cmark.NODE_ITEM] = function(md, last)
    local s = rtf.new()
    if md:len() == 1 and md:child():get_type() == cmark.NODE_PARAGRAPH then
        md = md:child()
    end
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    s = '\t• '..s
    if not last then
        s = s..'\n'
    end
    add_attr(s, {
        type = 'indent',
        level = 38,
    })
    return s
end

parsers[cmark.NODE_LINK] = function(md, last)
    local s = rtf.new()
    for v in md:loopchildren() do
        s = s..parse(v, last)
    end
    add_attr(s, {
        type = 'link',
        url = md:get_url(),
    })
    return s
end

parsers[cmark.NODE_IMAGE] = function(md)
    local url = md:get_url()
    if is_youtube(url) then
        local s = rtf.new(url)
        add_attr(s, {
            type = 'link',
            url = url,
        })
        return s
    else
        local s = rtf.new(' ')
        add_attr(s, {
            type = 'image',
            url = url,
        })
        return s
    end
end

local md = {}
local mt = {__index = md}

function md.new(width)
    local self = setmetatable({}, mt)
    self.width = width
    self.m = objc.UITextView:alloc():initWithFrame{{0, 0}, {width, 0}}
    self.m:setScrollEnabled(false)
    self.m:setBackgroundColor(objc.UIColor:clearColor())
    self.m:setEditable(false)

    self.tap = ns.target:new()
    local gesture = objc.UITapGestureRecognizer:alloc():initWithTarget_action(self.tap.m, self.tap.sel)
    function self.tap.onaction()
        self.m:setSelectedTextRange(nil)
        if not self.links then return end
        local pos = gesture:locationInView(self.m)
        local inset = self.m:textContainerInset()
        pos.x = pos.x - inset.left
        pos.y = pos.y - inset.top

        local idx = self.m:layoutManager():characterIndexForPoint_inTextContainer_fractionOfDistanceBetweenInsertionPoints(pos, self.m:textContainer(), nil)
        for i,v in ipairs(self.links) do
            if idx >= v.pos and idx < v.pos + v.length then
                objc.UIApplication:sharedApplication():openURL(objc.NSURL:URLWithString(v.url))
                --C.alert_display_c('URL: '..v.url, 'Cool', nil, nil)
                break
            end
        end
    end
    self.m:addGestureRecognizer(gesture)
    self.m:setUserInteractionEnabled(true)

    return self
end

function md:init(blob)
    if self.blob == blob then return end

    self.m:setFrame{self.m:frame().origin, {self.width, 0}}

    self.blob = blob
    if self.rtf then
        self.rtf.m:release()
        self.rtf.m = nil
    end
    self.rtf = parse(cmark.new(blob), true)
    self.rtf.m:addAttributes_range({
        [C.NSFontAttributeName] = fonts[FONT_NORMAL],
        [C.NSForegroundColorAttributeName] = objc.UIColor:whiteColor(),
    }, ffi.new('NSRange', 0, self.rtf.m:length()))

    local initted = false

    local IMG_MAX_AREA = 160 * 160
    local IMG_MAX_WIDTH = self.width
    local IMG_MAX_HEIGHT = 560

    self.links = {}
    for i,v in ipairs(self.rtf.attr) do
        if v.type == 'font' then
            self.rtf.m:addAttributes_range({
                [C.NSFontAttributeName] = fonts[v.font],
            }, ffi.new('NSRange', v.pos, v.length))
        elseif v.type == 'indent' then
            local style = objc.NSMutableParagraphStyle:alloc():init()
            style:setHeadIndent(v.level)
            self.rtf.m:addAttributes_range({
                [C.NSParagraphStyleAttributeName] = style,
            }, ffi.new('NSRange', v.pos, v.length))
        elseif v.type == 'link' then
            self.rtf.m:addAttributes_range({
                [C.NSForegroundColorAttributeName] = COLOR(0x9bb2f0aa),
            }, ffi.new('NSRange', v.pos, v.length))
            table.insert(self.links, v)
        elseif v.type == 'image' then
            dl_image(self.rtf, v.url, function(rtf, img, errcode)
                if not(rtf == self.rtf) then return end
                if not img then return end
                local attach = objc.NSTextAttachment:alloc():init()
                local origin = attach:bounds().origin
                local width, height = img:size().width, img:size().height
                if width * height > IMG_MAX_AREA then
                    local scale = math.sqrt(IMG_MAX_AREA / (width * height))
                    width = width * scale
                    height = height * scale
                end
                if width > IMG_MAX_WIDTH then
                    local scale = IMG_MAX_WIDTH / width
                    width = IMG_MAX_WIDTH
                    height = height * scale
                end
                if height > IMG_MAX_HEIGHT then
                    local scale = IMG_MAX_HEIGHT / height
                    width = width * scale
                    height = IMG_MAX_HEIGHT
                end
                attach:setBounds{origin,{width,height}}
                attach:setImage(img)
                local attr_str = objc.NSAttributedString:attributedStringWithAttachment(attach)
                self.rtf.m:replaceCharactersInRange_withAttributedString(
                    ffi.new('NSRange', v.pos, v.length),
                    attr_str
                )
                if initted then
                    self:update()
                end
            end)
        end
    end

    self:update()
    initted = true
    return self
end

function md:update()
    self.m:setAttributedText(self.rtf.m)
    self.m:sizeToFit()
    self.m:setFrame{self.m:frame().origin,{self.width, self.m:frame().size.height}}
    if self.onupdate then
        self:onupdate()
    end
end

return md
