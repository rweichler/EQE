local top = require 'page.history.top'
local history = require 'history'

local result, tbl = top('SELECT * FROM history WHERE deleted=0 AND duration >= '..history.minimum_duration..' ORDER BY id DESC;', function(song)
    return song.title or 'NULL', (song.artist or 'NULL')..' - '..(song.album or 'NULL')
end)


function tbl:caneditcell(section, row)
    return true
end

function tbl:editcell(section, row, style)
    if not(style == UITableViewCellEditingStyleDelete) then return end
    history.db:exec('UPDATE HISTORY SET deleted=1 WHERE id='..self.songs[row].id)

    table.remove(self.songs, row)
    self.section = {#self.songs}

    local rows = objc.toobj{objc.NSIndexPath:indexPathForRow_inSection(row - 1, section - 1)}
    self.m:deleteRowsAtIndexPaths_withRowAnimation(rows, UITableViewRowAnimationFade)
end


return result
