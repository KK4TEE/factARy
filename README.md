# factARy
Read data from a circuit network in Factorio, convert it to JSON, and make it available through a web server!

![Hologrpahic Factory Map](doc/img/readme_banner.jpg?raw=true "Holographic factory map running on the Microsoft HoloLens")

I'm in the process of building an mod + app to visualize all of the game data I can get my hands on into Augmented reality. If you've got a HoloLens, then you can turn your room into a virtual observation center for your factory. If you don't have AR glasses, you can run the system on your Android device or 2nd monitor too.

It's made of three components: a mod to Factorio, the viewer client with the extra screen, and a small python server to bind them together.

# Current status: Proof of Concept only
* Factorio Mod:  Mostly Functional, included in this repository
* Python Server: Functional, included in this repository
* Unity Viewer:  Somewhat Functional, not included yet. 

I will continue development in spare time. The Unity client currently uses some proprietary plugins that can't be shared in an open source project, so I will see about adjusting the project to share what I can.

# Requirements: 
* Full legal copy of Factorio
* Python 3
* CherryPy for Python 3

# Instructions:
* Copy the factorio_mod folder to your Factorio directory (" C:\Users\USERNAME\AppData\Roaming\Factorio\mods" by default
* Rename the factorio_mod directory to "factARy_0.1.0"
* Run server.py with Python 3
* Start Factorio, enable the mod, and launch a game
* Open a web browser to "http://127.0.0.1:8042" and test if the site greats you
* View the JSON readout located at "http://127.0.0.1:8042/json"
* Enjoy the data output from your factory! 

Data can be streamed as often as you like (multiple times per second, even on multiple web devices or browsers!). It will only read from the game file a maximum of 60 times per second and then cache the results. Currently the performance is such that it takes multiple in-game Ticks to write out the data. I'm observing updates about 5 times per second with an in-game performance hit of around 20% to my FPS. I'm hoping to improve this with optimizations.

This is still very much a work in progress, so please feel free to suggest ideas!


