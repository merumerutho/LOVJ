# LOVELive2P
### LÖVE minimal Live-Coding collaborative framework 


LOVELive2P (not [that kind](https://en.wikipedia.org/wiki/Love_Live!) of Love Live) is a minimal [LÖVE](https://love2d.org/) framework to create, explore, play interactively with the code in order to creat visuals in a live coding setting or during a live music performance.

It is flexible enough in order to support:
- "1 player" scenarios, with the livecoder/artist handling entirely the code and controls of the visuals.
- "2+ players" scenario where multiple artists concur to provide signals to control the visuals (through the UDP protocol). 
Here, the livecoder, on top of editing the code, may dynamically select and "wire" the external signals to the parameters of choice inside the code.


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
This will launch *LOVELive2P*, which will load the default demo contained in the "demos" folder.

- To test the communication, go into the "test_publisher" folder and run again:
```sh
love .
```
to open a test script to communicate with LOVELive2P.

## Creating scripts
Scripts can be created by using demos as references.
They must contain, similarly to any LÖVE2D script:
- A patch.init() method called upon love.load()
- A patch.draw() method called upon love.draw()
- A patch.update() method called upon love.update()

The "patch" object must be returned once the script is initialized.


## MIDI to UDP
TBD.