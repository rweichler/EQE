local top = require 'page.history.top'
local history = require 'history'

return top('SELECT *, count(title) AS count FROM history WHERE deleted=0 AND duration >= '..history.minimum_duration..' GROUP BY title, artist ORDER BY count DESC;', function(song)
    return (song.artist or 'NULL')..' - '..(song.title or 'NULL')
end)
