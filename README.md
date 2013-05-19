# Tanks

Tanks is a Gosu-based simple, online, real-time multi-player game, based on the popular retro game, [Tank Battalion](http://en.wikipedia.org/wiki/Tank_Battalion). Rev up your tank and battle it out in the deadly Tanks arena, if you dare!

## Install

Tanks primarily uses 2 external libraries -- [Gosu](http://www.libgosu.org/) and Celluloid-IO (https://github.com/celluloid/celluloid-io). Install the needed and related gems by running `bundle install`. Once you've done that you're good to go!

If you encounter problems when running a variant of Linux, make sure you have all the dependencies install. Read up more about it here - https://github.com/jlnr/gosu/wiki/Getting-Started-on-Linux

As of writing, it's only been tested on a Linux machine and on a Mac OS X Mountain Lion, running in Ruby 1.9.3 or Ruby 2.0.0.


## Run


Just do this:

1. Run the game server. Server and port are optional, defaulting to 0.0.0.0 and 1234 by default.
 
    `$ ruby arena.rb <server> <port>`
     
2. Run the game client in any computer in the same network, and connecting to the server.

    `$ ruby player.rb  <server> <port> <player name> <tank color>`
      
 All the parameters are optional. By default, a random name is used, along with a random color. The default server IP is 0.0.0.0 and the default port is 1234. Tank colors can be any [X11 color names](http://en.wikipedia.org/wiki/Web_colors) in snake case e.g. `yellow_green`, `light_steel_blue` and so on. 
   
## Customize


Tanks is completely customizable and extensible. The default mode is a deathmatch, but you can always make it capture the flag or a team deathmatch or a points competition by tweaking the game logic. You can also customize any component of the game:

### Map

Open up the file `assets/map.txt`. Each `.` or `#` corresponds to how the map is laid out. Check out `map.rb` for other tiles for the map. You can also check `settings.rb` to see the other types of tiles.

### Sprites

The sprites used in the game can be changed too. The sprites in this game are from [SpriteLib](http://www.widgetworx.com/widgetworx/portfolio/spritelib.html) and placed in `assets/spritesheet.png`. The original is included as `assets/tankbrigade.png`. You can change the spritesheet, you just need to change the settings in the `SpriteImage` module. The assumption is that each sprite in the spritesheet is 32x32 pixels.

### Sound

The sound files in the game can also be changed, and each action can also have a sound. The `assets/bang.wav` is the sound when the tanks fires a bullet, the `assets/crash.wav` is the sound when a bullet hits the tank and the `assets/boom.wav` is the sound when the tank is destroyed.
