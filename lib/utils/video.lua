-- video.lua
--
-- Handler of video utilities
--

local videoutils = {}

--- @public handleLoop Upon vide play termination, it rewinds and starts the video again, creating a loop.
function videoutils.handleLoop(vid)
    if not vid.playbackSpeed then vid.playbackSpeed = 1 end
    -- without loop_point: try to reach end of video then restart
    -- with loop point: reach loop point and then restart
    if not vid.loopStart then vid.loopStart = 0 end
    -- ...
    vid.handle:seek(vid.pos + vid.playbackSpeed/60)
    -- ...
    if (vid.handle:tell() >= vid.pos and not vid.loopEnd) or
            (vid.loopEnd and vid.handle:tell() < vid.loopEnd) then
        vid.pos = vid.handle:tell()
    else
        vid.handle:seek(vid.loopStart)
        vid.handle:play()
        vid.pos = vid.loopStart
    end
end

return videoutils