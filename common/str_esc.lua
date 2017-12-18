return function(s)
    return '[['..string.gsub(s, '%]%]', "]]..']]'..[[")..']]'
end
