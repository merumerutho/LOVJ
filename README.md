# LOVJ
### A LÖVE2D VJing framework 

LOVJ aims to be a [LÖVE](https://love2d.org/) framework to create a live-coding, interactive VJing environment mainly targeted at live music performances.
It revolves around the concept of video patches: these can be loaded, sequenced, and mixed in several ways.

It allows interaction with the patches through:
- code editing (livecoding)
- user controls (mouse / keyboard / hid devices)
- external controls (midi, osc, etc.)


## Setup
- [LÖVE](https://love2d.org/) version 11.4
- Add LOVE2D bin folder to your PATH variable
- Download/clone this repository.
- Go inside the main folder (with the main.lua script) and run:
```sh
love .
```

## Issues
LOVJ is still in a work-in-progress state. Development is messy and several features are still broken. 
It can be played with, but don't expect the software to be working reliably in its current state. Check Issue tracker for more info.


## Credits
- [usysrc](https://github.com/usysrc) for the original *LICK* library implementation.
- [rxi](https://github.com/rxi) Json library.


## MIDI to OSC
A simple tool to relay MIDI messages to OSC messages based on some configuration can be found [here](https://github.com/merumerutho/MIDI2OSC).