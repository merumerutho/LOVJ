# LOVJ
### A LÖVE VJing framework 


LOVJ (previously named [LOVELive2p](https://en.wikipedia.org/wiki/Love_Live!)) aims to be a [LÖVE](https://love2d.org/) framework to create, explore, play interactively with the code in order to creat visuals in a VJing setting or during a live music performance.

Shall be flexible enough to support:
- "1 player" scenarios, with the VJ handling entirely control of the visuals.
- "2+ players" scenario where multiple artists concur to provide signals to control the visuals (through the OSC protocol). 
Here, the VJ may handle the controls and on top, dynamically select and "wire" the external signals to the parameters of choice inside the code.


## TODOs
- Evaluate and reintroduce the livecoding feature (currently not working)
- Introduce Automations: Envelopes and LFOs. These shall be triggered by some specific configurable event (keyboard/timer function/OSC event) and might control any resource
- Make current patch and other major functions controllable by resources->general variables
- Add external patch load, add configuration save etc.
- A raymarching demo would be cool :)

## Requires
- [LÖVE](https://love2d.org/) version 11.3


## Credits
- [usysrc](https://github.com/usysrc) for its *LICK* library (here, modified to close properly a UDP socket upon hot-reloading).


## Use

- Make sure you have LÖVE (v11.3) installed and its binaries folder added to the PATH environment variable.
- Download/clone this repository.
- Go inside the main folder (with the main.lua script) and run:
```sh
love .
```
This will launch *LOVJ*, which will load the default demo contained in the "demos" folder.

- To test the communication, go into the "test_publisher" folder and run again:
```sh
love .
```
to open a test script to communicate with LOVELive2P.

## Creating scripts
Scripts can be created by using demos as references.
They must be Patches objects, similarly to any LÖVE2D script:
- A patch.init() method called upon love.load()
- A patch.draw() method called upon love.draw()
- A patch.update() method called upon love.update()


## MIDI to OSC
[Here](https://github.com/Merutochan/MIDI2OSC) 