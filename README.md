<center><img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/logo.png" width=500 /></center>

# LOVE2D VJing Framework
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

## Screenshots

<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/1.png" width=300/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/2.png" width=300/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/4.png" width=300/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/3.png" width=300/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/5.png" width=300/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/6.png" width=300/>


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
You should use them in combination with the **UP** or **DOWN** arrow keys to change the effect intensity, after selecting the corresponding effect with the **S** key.

- **W** for warp effect
- **K** kaleidoscope effect
- **G** blur effect

## Porting GLSL shaders
You can port GLSL shaders to LOVJ by creating a new patch in postProcess and readapt the shader code.

Keep in mind that in order to modify the shader parameters, you need to pass everything in `cfg/cfg_shaders.lua`

Assuming that your shader is called "porting", this is how a shader should look like:
```lua
-- lib/shaders/postProcess/19_porting.glsl
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    -- your shader code here
}
```

### Passing time to shader
One common use case, is pass the time parameter to a shader:
```lua
-- cfg/cfg_shaders.lua
if string.find(shader.name, "porting") then
    shader.object:send("_time", cfg_timers.globalTimer.T)
end
```

### Passing a parameter to shader
Another useful common use case is to pass a parameter to the shader that can be controlled by the user.

In this specific case, your GLSL shader should look like
```glsl
external float _whateverParameter;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    ...
}
```

And in the `cfg_shaders.lua` file, you should add:
```lua
-- cfg/cfg_shaders.lua
-- ...
-- porting
if kp.isDown("m") then
    if kp.isDown("up") then s:set("_whateverParameter", (s:get("_whateverParameter") + 0.1)) end
    if kp.isDown("down") then s:set("_whateverParameter", (s:get("_whateverParameter") - 0.1)) end
end
```

Feel free to adapt the parameter name and the value to your needs, this is just an example that binds the parameter to the **M** key and allows to change it with the **UP** and **DOWN** arrow keys.

Then, in order to use the shader, you need to cycle through the effects with the **S** key, until you reach the desired effect.

## Issues
LOVJ is still in a work-in-progress state. Development is messy and several features are kind of broken. 
It can be played with, but don't expect the software to be working reliably in its current state. Check Issue tracker for more info.

## Running the demos
- Open _cfg/cfg_patches.lua_.
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