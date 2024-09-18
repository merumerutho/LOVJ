# LOVJ
### A LÖVE2D VJing framework 

![LOVJ logo](https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/logo.png)

LOVJ aims to be a [LÖVE](https://love2d.org/) framework to create a live-coding, interactive VJing environment mainly targeted at live music performances.
It revolves around the concept of video patches: these can be loaded, sequenced, and mixed in several ways.

It allows interaction with the patches through:
- code editing (with **livecoding** hot-reload features)
- common controls (mouse / keyboard / touch)
- external controls (**OSC**)

Moreover, it supports advanced functionalities such as:
- **GLSL** shaders support (for advanced rendering techniques, such as ray-marching).
- **Spout** Send/Receive functions (allowing streaming to/from external apps, feedback loops, etc.).
- **Savestates** (save/recall patches internal status quickly).
- **OSC** network server via **UDP**.


## Setup
- [LÖVE](https://love2d.org/) version 11.4+
- Add LOVE2D bin folder to your PATH variable
- Download/clone this repository.
- From this repo main folder (containing the main.lua script), run:
```sh
love .
```

## Usage
### General
- **F1 ... F12** to switch between patches.
- **CTRL + Return** toggle fullscreen.
- **CTRL + S** toggle shader on/off
- **CTRL + U** upscale
- **S** cycle through effects

### Visual effects adjustments
You should use them in combination with the **UP** or **DOWN** arrow keys to change the effect intensity, after selecting the effect with the **S** key.

- **W** warp
- **K** kaleidoscope
- **G** blur

## Issues
LOVJ is still in a work-in-progress state. Development is messy and several features are kind of broken. 
It can be played with, but don't expect the software to be working reliably in its current state. Check Issue tracker for more info.

## Running the demos
- Open _lib/cfg/cfg_patches.lua_.
- Edit the _defaultPatch_ or the _patches_ list.
- Run LOVJ.
- Select the chosen demo from _patches_ with the [F1 ... F12] keys.


## Credits
- [lick](https://github.com/usysrc/lick) original *LICK* implementation for live-coding features (MIT license).
- [json.lua v.0.1.2](https://github.com/rxi/json.lua) Json library (MIT license).
- [losc v.1.0.1](https://github.com/davidgranstrom/losc) Lua OSC library (MIT license).
- [Spout](https://spout.zeal.co/) Spout library (BSD-2 license).


## MIDI to OSC
A simple tool to relay MIDI messages to OSC messages based on some configuration can be found [here](https://github.com/merumerutho/MIDI2OSC).