-- clock.lua
--
-- Global transport clock for LOVJ. Owns the BPM, tracks continuous beat
-- position, and provides a 4/4 bar phase counter that everything else
-- (sequencers, modulators, patches) can read.
--
-- Usage from anywhere:
--   clock.bpm            -- current BPM
--   clock.beat           -- continuous beat count since last phase reset
--   clock.bar            -- continuous bar count (beat / beatsPerBar)
--   clock.beatPhase      -- fractional position within the bar (0 .. beatsPerBar)
--   clock.subBeat        -- fractional position within the current beat (0 .. 1)
--   clock.step16         -- 1/16th note position within the bar (1 .. 16)
--   clock.step           -- raw step count since phase reset (1-indexed, never wraps)
--
--   clock.setBPM(bpm)    -- set BPM numerically
--   clock.tap()          -- tap-tempo (averages last 8 taps)
--   clock.resetPhase()   -- align beat 0 to "now" (re-sync with music)
--   clock.nudge(dt)      -- shift phase by dt seconds (fine-tune alignment)
--

local cfg_bpm = require("cfg/cfg_bpm")

local clock = {}

-- State
clock.bpm          = cfg_bpm.default_bpm
clock.beatsPerBar  = 4
clock.startTime    = 0

-- Derived (updated each frame by clock.update)
clock.beat         = 0
clock.bar          = 0
clock.beatPhase    = 0     -- 0 .. beatsPerBar
clock.subBeat      = 0     -- 0 .. 1
clock.step16       = 1     -- 1 .. 16
clock.step         = 1     -- monotonic 1/16 count since reset

-- Tap-tempo state
clock.tapTimes     = {}
clock.maxTaps      = 8


function clock.init(bpm)
    clock.bpm = bpm or cfg_bpm.default_bpm
    clock.startTime = love.timer.getTime()
    clock.tapTimes = {}
end


--- Set BPM numerically. Preserves current phase so there's no audible jump.
function clock.setBPM(bpm)
    if not bpm or bpm <= 0 then return end
    -- Compute current beat position at old BPM, then adjust startTime so the
    -- same beat position holds at the new BPM.
    local now = love.timer.getTime()
    local currentBeat = (now - clock.startTime) * clock.bpm / 60
    clock.startTime = now - currentBeat * 60 / bpm
    clock.bpm = bpm
end


--- Tap-tempo. Call repeatedly; BPM is derived from the average interval
--- of the last `maxTaps` taps. Resets after 5 seconds of inactivity.
clock.tapTimeout = 5

function clock.tap()
    local now = love.timer.getTime()
    if #clock.tapTimes > 0 and (now - clock.tapTimes[#clock.tapTimes]) > clock.tapTimeout then
        clock.tapTimes = {}
    end
    table.insert(clock.tapTimes, now)
    if #clock.tapTimes > clock.maxTaps then
        table.remove(clock.tapTimes, 1)
    end
    if #clock.tapTimes >= 2 then
        local total = 0
        for i = 2, #clock.tapTimes do
            total = total + (clock.tapTimes[i] - clock.tapTimes[i - 1])
        end
        local avg = total / (#clock.tapTimes - 1)
        clock.setBPM(60 / avg)
    end
end


--- Reset phase: beat 0 starts "now". Use this to align the sequencer
--- with the downbeat of the music.
function clock.resetPhase()
    clock.startTime = love.timer.getTime()
end


--- Nudge phase by `dt` seconds (positive = shift forward in time,
--- negative = shift back). Use for fine-tuning alignment.
function clock.nudge(dt)
    clock.startTime = clock.startTime - (dt or 0)
end


--- Seconds per beat at the current BPM.
function clock.beatDuration()
    return 60 / clock.bpm
end


--- Seconds per step for a given divider (e.g. 4 = 1/16th notes).
function clock.stepDuration(divider)
    return 60 / (clock.bpm * (divider or 4))
end


--- Musical-division lookup: how many beats each division spans.
local TempoDivisions = require("lib/tempo_divisions")
clock.divisions = TempoDivisions.byLabel

--- Return the frequency in Hz for a named musical division at the current BPM.
--- E.g. clock.syncRate("1bar") at 120 BPM → 0.5 Hz (one cycle every 2 seconds).
function clock.syncRate(division)
    local beats = clock.divisions[division] or 4
    return clock.bpm / (60 * beats)
end


--- Convert a beat-relative rate to Hz at the current BPM.
--- rate = cycles per beat; result = cycles per second.
function clock.beatsToHz(rate)
    return rate * clock.bpm / 60
end


--- Call once per frame. Updates all derived fields.
function clock.update()
    local now = love.timer.getTime()
    local elapsed = now - clock.startTime
    local beatsPerSec = clock.bpm / 60

    clock.beat      = elapsed * beatsPerSec
    clock.bar       = clock.beat / clock.beatsPerBar
    clock.beatPhase = clock.beat % clock.beatsPerBar
    clock.subBeat   = clock.beat % 1
    clock.step16    = math.floor(clock.beat * 4) % 16 + 1
    clock.step      = math.floor(clock.beat * 4) + 1
end


return clock
