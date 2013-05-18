Tanks!
=====

Tanks! is a Gosu-based simple, online, real-time multi-player game, based on the popular retro game, [Tank Battalion](http://en.wikipedia.org/wiki/Tank_Battalion).

Installing Tanks!
=================

Gosu primarily uses 2 external libraries -- [Gosu](http://www.libgosu.org/) and Celluloid-IO (). Install the needed and related gems by running `bundle install`. Once you've done that you're good to go!

If you encounter problems when running a variant of Linux, make sure you have all the dependencies install. Read up more about it here - https://github.com/jlnr/gosu/wiki/Getting-Started-on-Linux

As of writing, it's only been tested on a Linux machine and on a Mac OS X Mountain Lion, running in Ruby 1.9.3 or Ruby 2.0.0.


Running Tanks! 
==============

Just do this:

1. Run the game server. Server and port are optional, defaulting to 0.0.0.0 and 1234 by default.
 
    `$ ruby ./arena.rb <server> <port>`
     
2. Run the game client in any computer in the same network, and connecting to the server.

    `$ ruby ./player.rb  <server> <port> <player name> <tank color>`
      
 All the parameters are optional. By default, a random name is used, along with a random color. The default server IP is 0.0.0.0 and the default port is 1234.
 
 For tank colors, chose one of the following:
 * red
 * blue
 * green
 * purple
   
   

