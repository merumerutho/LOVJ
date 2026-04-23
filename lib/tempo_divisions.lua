-- tempo_divisions.lua
--
-- Single source of truth for musical tempo divisions.
-- Each entry has a label and a beat value (how many quarter-note beats it spans).
-- Sorted from longest to shortest duration.
--
-- Dotted notes are 1.5x the straight duration (suffix ".").
-- Triplet notes are 2/3 the straight duration (suffix "T").

local TempoDivisions = {}

TempoDivisions.list = {
    { label = "16 bars",  beats = 64 },
    { label = "8 bars",   beats = 32 },
    { label = "4 bars",   beats = 16 },
    { label = "2 bars",   beats = 8 },
    { label = "1/1",      beats = 4 },
    { label = "1/2.",     beats = 3 },
    { label = "1/2",      beats = 2 },
    { label = "1/2T",     beats = 4 / 3 },
    { label = "1/4.",     beats = 1.5 },
    { label = "1/4",      beats = 1 },
    { label = "1/4T",     beats = 2 / 3 },
    { label = "1/8.",     beats = 0.75 },
    { label = "1/8",      beats = 0.5 },
    { label = "1/8T",     beats = 1 / 3 },
    { label = "1/16.",    beats = 0.375 },
    { label = "1/16",     beats = 0.25 },
    { label = "1/16T",    beats = 1 / 6 },
    { label = "1/32",     beats = 0.125 },
}

TempoDivisions.byLabel = {}
for _, d in ipairs(TempoDivisions.list) do
    TempoDivisions.byLabel[d.label] = d.beats
end

return TempoDivisions
