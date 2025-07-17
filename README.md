<center><img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/logo.png" width=500 /></center>

# LOVJ - A LÖVE-based VJing Framework



## 📖 Overview

LOVJ is a framework for the LÖVE 2D game engine, designed to create a live-coding and interactive VJing environment. It's primarily aimed at live music performances, allowing for the creation, sequencing, and mixing of video patches in various ways.

## ✨ Features

- **Live-Coding:** Edit code on-the-fly with hot-reloading capabilities.
- **Interactive Controls:** Control patches through mouse, keyboard, touch, and OSC.
- **GLSL Shaders:** Advanced rendering with GLSL shaders, including support for ray-marching.
- **Spout Integration:** Stream video to and from other applications using Spout.
- **Savestates:** Quickly save and recall the internal state of patches.
- **OSC Networking:** Built-in OSC server for external control.
- **Patch-based Architecture:** Modular design based on video patches that can be loaded, sequenced, and mixed.

## 📹 Screenshots

<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/1.png" width=250/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/2.png" width=250/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/4.png" width=250/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/3.png" width=250/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/5.png" width=250/>
<img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/doc/img/screen/6.png" width=250/>


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

## 🙏 Acknowledgments (Optional)

- [lick](https://github.com/usysrc/lick): For the live-coding features.
- [json.lua](https://github.com/rxi/json.lua): JSON library.
- [losc](https://github.com/davidgranstrom/losc): Lua OSC library.
- [Spout](https://spout.zeal.co/): Spout library for video sharing.
