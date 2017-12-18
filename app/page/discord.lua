local page = {}
page.title = 'Discord chat'
page.icon = IMG('discord.png', PAGE_ICON_COLOR):retain()

local url = 'https://discord.gg/RSJWAuX'

function page:init()
    objc.UIApplication:sharedApplication():openURL(objc.NSURL:URLWithString(url))
end

return page
