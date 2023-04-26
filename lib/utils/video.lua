-- video.lua
--
-- Handler of video utilities
--

local videoutils = {}

--- @public handleLoop Upon vide play termination, it rewinds and starts the video again, creating a loop.
function videoutils.handleLoop(vid, loop_start, loop_end)
    -- without loop_point: try to reach end of video then restart
    -- with loop point: reach loop point and then restart
    loop_start = 0 or loop_start
    -- ...
    if (vid.handle:tell() >= vid.pos and not loop_end) or
            (loop_end and vid.handle:tell() < loop_end) then
        vid.pos = vid.handle:tell()
    else
        vid.handle:seek(loop_start)
        vid.handle:play()
        vid.pos = loop_start
    end
end

return videoutils