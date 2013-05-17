WIDTH       = 640
HEIGHT      = 480

module SpriteImage
  Grass = 102
  Earth = 101
  Gravel = 100
  Wall = 59
  Bullet= 28
  Tank = 39
end

NAME        = "Tanks!"
SPRITESHEET = "assets/spritesheet.png"
MAPFILE     = "assets/map.txt"
DEFAULT_HIT_POINTS = 10

COLORS = {'red'     => Gosu::Color::RED.gl,
          'green'   => Gosu::Color::GREEN.gl,
          'blue'    => Gosu::Color::BLUE.gl,
          'yellow'  => Gosu::Color::YELLOW.gl,
          'aqua'    => Gosu::Color::AQUA.gl,
          'fuchsia' => Gosu::Color::FUCHSIA.gl}


SERVER = '0.0.0.0'
PORT        = 1234

require 'randexp'
PLAYER_NAME = Randgen.first_name(length: 6)
PLAYER_COLOR = COLORS.values[rand(COLORS.size)]