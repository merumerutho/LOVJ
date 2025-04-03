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

This is how a GLSL shader should be implemented to be compatible with LOVJ.
```C++
// @param vec4  _param1 {0.0, 1.0, 0.0, 1.0} //
// @param vec2  _param2 {-0.1, 0.1} //
// @param float _param3 -0.1 //

extern vec4  _param1;
extern vec2  _param2;
extern float _param3;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    -- your shader code here  (must include usage of _param1, _param2, _param3)
}
```
Notice the ```@param <type> <name> <default_value>``` tags. 

They are used to automatically instance dedicated resources for each shader parameter, with a default initial value.

These are instanced with the following name structure: _<shadername_paramname>_

### Passing value to shader
To update the value of the shader parameter, one can use the following in the update cycle, as an example:
```lua
-- cfg/cfg_shaders.lua
if string.find(shader.name, "yourShaderName") then
    shader.object:send("_param3", s:get("yourShaderName__param3"))
end
```

And to change the value:
```lua
-- cfg/cfg_shaders.lua
-- ...
-- yourShaderName
if kp.isDown("m") then
    if kp.isDown("up") then s:set("yourShaderName__param3", (s:get("yourShaderName__param3") + 0.1)) end
    if kp.isDown("down") then s:set("yourShaderName__param3", (s:get("yourShaderName__param3") - 0.1)) end
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