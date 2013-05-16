Tanks!
=====

Tanks! is a Gosu-based simple, online, real-time multi-player game, based on the popular retro game, [Tank Battalion](http://en.wikipedia.org/wiki/Tank_Battalion).

Running Tanks! is simple: 

1. Run the game server. Server and port are optional, defaulting to 0.0.0.0 and 1234 by default.
    $ ruby ./arena.rb <server> <port>
     
2. Run the game client in any computer in the same network, and connecting to the server.

    $ ruby ./client.rb  <server> <port> <player name> <tank color>
      
   All the parameters are optional. By default, a random name is used, along with a random color. The default server IP is 0.0.0.0 and the default port is 1234.
   
   For tank colors, chose one of the following:
   * red
   * blue
   * green
   * yellow
   * aqua
   * fuchsia
   
   

