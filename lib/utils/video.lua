videoutils = {}

function videoutils.handleLoop(vid)
    -- loop video
    if vid.handle:tell() >= vid.pos then
        vid.pos = vid.handle:tell()
    else
        vid.handle:rewind()
        vid.handle:play()
        vid.pos = 0
    end
end

return videoutils