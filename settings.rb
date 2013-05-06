WIDTH       = 640
HEIGHT      = 480

module SpriteImage
  Grass = 102
  Earth = 101
  Gravel = 100
  Wall = 59
  Bullet= 28
  Tank = 39
  Explosion = 27
end

SPRITESHEET = "assets/spritesheet.png"
MAPFILE     = "assets/map.txt"
DEFAULT_HIT_POINTS = 10

NAME        = "Tanks!"

SERVER      = '0.0.0.0'
PORT        = 1234

require 'randexp'
PLAYER_NAME = Randgen.first_name(length: 6)
PLAYER_COLOR = 0xff000000 + rand(0xffffffff - 0xff000000)