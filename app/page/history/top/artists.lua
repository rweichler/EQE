local top = require 'page.history.top'
local history = require 'history'

return top('SELECT *, count(artist) AS count FROM history WHERE deleted=0 AND duration >= '..history.minimum_duration..' GROUP BY artist ORDER BY count DESC;', function(song)
    return song.artist or 'NULL'
end)
