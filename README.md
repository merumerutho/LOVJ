<center><img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/data/app/LOVJ.png" width=500 /></center>

# LOVJ - LÖVE2D VJing Framework

## 📖 Overview

LOVJ is a framework based on LÖVE2D, designed as a live-coding and interactive VJing environment.
It's primarily aimed at live music performances, allowing for the creation, sequencing, and mixing of video patches.

## ✨ Features

### Current

- **Interactive Controls:** Control patches through mouse, keyboard, touch and gamepads.
- **GLSL Shaders:** Builtin support for GLSL shaders, write your own filters, ray-marchers, etc.
- **Spout Integration:** Stream video to and from other applications using Spout.
- **Savestates:** Quickly save and recall the internal state of patches.
- **Patch-based Architecture:** Modular design based on video patches that can be loaded, sequenced, and mixed.
- **MIDI Support:** Connect MIDI controllers for real-time parameter control and patch triggering.
- **OSC Networking:** Built-in OSC server for external control and integration with other applications.

### Planned

- **Live-Coding:** Edit code on-the-fly with hot-reloading capabilities.

## 📋 Prerequisites

- [LÖVE](https://love2d.org/) version 11.4 or higher.

## 🚀 Installation

1.  Clone the repository with all submodules:
    ```sh
    git clone --recurse-submodules https://github.com/merumerutho/LOVJ.git
    ```
2.  Add the LÖVE binary directory to your system's PATH variable.
3.  Navigate to the cloned repository's root directory (the one containing `main.lua`).
4.  Run the application with the following command:
    ```sh
    love .
    ```

## 🔧 Usage

### General Controls

-   **F1 - F12:** Switch between loaded patches.
-   **Ctrl + Enter:** Toggle fullscreen mode.
-   **Ctrl + S:** Toggle shaders on or off.
-   **Ctrl + U:** Change the upscaling mode.
-   **S:** Cycle through available visual effects.

### MIDI and OSC Control

LOVJ supports external control through MIDI and OSC protocols:

#### MIDI Setup
1. Configure MIDI connections in `cfg/cfg_midi_mapping.lua`
2. Set `enabled = true` for your MIDI device in the connections section
3. Map MIDI CC, notes, and program changes to LOVJ commands
4. Use auto-detection or specify device names/indices

**Example MIDI mappings:**
- CC1: Switch patches
- CC7: Global volume control  
- Notes 60-67: Trigger patches 1-8
- Program changes: Load specific patches

#### OSC Setup
1. Configure OSC connections in `cfg/cfg_osc_mapping.lua`
2. Set connection address, port, and enable the connection
3. Map OSC addresses to LOVJ commands using direct or pattern mappings

**Example OSC addresses:**
- `/lovj/global/selectedPatch <slot>`: Switch to patch slot
- `/lovj/patch/<slot>/param/<name> <value>`: Set patch parameter
- `/lovj/shader/<slot>/<layer>/param/<name> <value>`: Set shader parameter
- `/lovj/system/fullscreen <0|1>`: Toggle fullscreen


## ⚙️ Configuration (Optional)

LOVJ's behavior can be customized through the various `.lua` files in the `cfg` directory. Here are some of the key configuration files:

-   `cfg/cfg_app.lua`: Application title and icon.
-   `cfg/cfg_connections.lua`: UDP and OSC connection settings.
-   `cfg/cfg_controls.lua`: General (non-patch-specific) input controls.
-   `cfg/cfg_patches.lua`: Default patch and the list of patches to load.
-   `cfg/cfg_screen.lua`: Screen resolution and windowing settings.
-   `cfg/cfg_shaders.lua`: Shader configurations.
-   `cfg/cfg_spout.lua`: Spout sender and receiver settings.

### Porting GLSL shaders
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


## 🤝 Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [lick](https://github.com/usysrc/lick): For the live-coding features.
- [json.lua](https://github.com/rxi/json.lua): JSON library.
- [Spout](https://spout.zeal.co/): Spout library for video sharing.
- [SiENcE/lovemidi](https://github.com/SiENcE/lovemidi) SiENcE for lovemidi.