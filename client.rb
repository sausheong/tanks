require 'gosu'
require 'celluloid/io'
require 'json'

require './settings'
require './lib'
require './map'
require './tank'
require './shot'

include Gosu

class Client
  include Celluloid::IO

  def initialize(server, port)
    begin
      @socket = TCPSocket.new(server, port)
    rescue
      $error_message = "Cannot find game server."
    end
  end

  def send_message(message)
    @socket.write(message) if @socket
  end

  def read_message
    @socket.readpartial(4096) if @socket
  end

end

class GameWindow < Window

  attr_reader :spritesheet, :player, :map, :client

  def initialize(server, port, player, color)
    super(WIDTH, HEIGHT, false)
    self.caption = NAME
    @spritesheet = Image.load_tiles(self, SPRITESHEET, 33, 33, true)
    @map = Map.new(self, MAPFILE)  # map representing the movable area
    @client = Client.new(server, port) # client that communicates with the server

    @player = player # player name
    @font = Font.new(self, 'Courier New', 20)  # for the player names

    # randomly assign a position to start
    px, py = *random_position
    while @map.solid?(px, py) do
      px, py = *random_position
    end

    @players = [] # list of all player names

    @me = Tank.new(self, SpriteImage::Tank, player, px, py, 0.0, DEFAULT_HIT_POINTS, color) # create tank representing the player
    @my_shots = [] # a list of my shots

    @other_tanks = {} # hash of player names => tank objects (other than myself)
    @other_shots = {} # a hash of player names => shot objects in an array (other than mine)

    @explosions = []

    @messages = [] # list of messages to send to the server at the end of each round

    # send message to let server know that this player has signed in
    add_to_messages('obj', @me.uuid, 'tank', @me.sprite_image, @player, @me.x, @me.y, @me.angle, @me.points, color)
    @explosions = []
  end

  def add_to_messages(message_type, uuid, sprite_type, sprite_image, player_name, x, y, angle, points=nil, color=nil)
    message = "#{message_type}|#{uuid}|#{sprite_type}|#{sprite_image}|#{player_name}|#{x}|#{y}|#{angle}|#{points}|#{color}"
    @messages << message
  end

  def add_shot(shot)
    @my_shots << shot
    add_to_messages('obj', shot.uuid, 'shot', SpriteImage::Bullet,  @player, @me.x, @me.y, @me.angle)
  end

  def remove_shot(shot)
    @my_shots.delete shot
    add_to_messages('del', shot.uuid, 'shot', SpriteImage::Bullet, @player, @me.x, @me.y, @me.angle)
  end

  def hit_tank(player)
    tank = @other_tanks[player]
    tank.hit if tank.alive?
    add_to_messages('obj', tank.uuid, 'tank', tank.sprite_image, tank.player, tank.x, tank.y, tank.angle, tank.points, tank.color)
  end

  def move_tank
    accelerate = false
    if button_down? KbLeft
      @me.go_left
      accelerate = true
    elsif button_down? KbRight
      @me.go_right
      accelerate = true
    elsif button_down? KbUp
      @me.go_up
      accelerate = true
    elsif button_down? KbDown
      @me.go_down
      accelerate = true
    end
    @me.accelerate if accelerate
  end

  def update
    move_tank
    @me.shoot
    px, py = @me.x, @me.y
    @me.move

    # don't hit the wall or go outside of the battlefield
    if @me.hit_wall?(@map) or @me.outside_battlefield?
      @me.warp_to(px, py)
    end

    # don't hit another tank
    @other_tanks.each do |player, tank|
      if tank.alive?
        if @me.collide_with?(tank.x, tank.y, tank.x+32, tank.y+32)
          @me.warp_to(px, py)
        end
      end
    end

    # tell the server that the player has moved
    add_to_messages('obj', @me.uuid, 'tank', @me.sprite_image, @player, @me.x, @me.y, @me.angle, @me.points, @me.color)

    # move my shots and what happens when they move
    @my_shots.each do |shot|
      shot.update # move the bullet
      # when my bullet hits a tank
      @other_tanks.each do |player, tank|
        if tank.collide_with?(shot.x, shot.y, shot.x+16, shot.y+16)
          remove_shot(shot)
          hit_tank(player)
          unless tank.alive?
            exp = Explosion.new(self, SpriteImage::Explosion, tank.x, tank.y)
            @explosions << exp
            add_to_messages('obj', exp.uuid, 'explosion',  SpriteImage::Explosion, @player, exp.x, exp.y, 0.0)
          end
        end
      end
      # tell the server the bullet has moved
      add_to_messages('obj', shot.uuid, 'shot',  SpriteImage::Bullet, @player, shot.x, shot.y, shot.angle)
    end

    # send collected messages to the server
    @client.send_message @messages.join("\n")
    @messages.clear
    begin
      msg = @client.read_message
      data = msg.split("\n")
      # create sprites or alter existing sprites from messages from the server
      data.each do |row|
        sprite = row.split("|")

        player = sprite[3]
        case sprite[1]          
        when 'tank'          
          unless player == @player                        
            if @other_tanks[player]
               @other_tanks[player].points = sprite[7].to_i
               @other_tanks[player].warp_to(sprite[4], sprite[5], sprite[6])
            else
              @other_tanks[player] = Tank.from_sprite(self, sprite)
            end
          else
            @me.points = sprite[7].to_i
          end
          
        when 'shot'
          unless player == @player
            if @other_shots[player]
              @other_shots[player].warp_to(sprite[4], sprite[5], sprite[6])                
            else
              @other_shots[player] = Shot.from_sprite(self, sprite)
            end
          end
        when 'explosion'
          @explosions << Explosion.from_sprite(self, sprite)
        end
      end

      # remove sprites not in the messages from the server
      @other_tanks.values.each do |tank|
        # tank.uuid = 
      end

    rescue Exception => e
      p $!
    end

  end

  def draw
    @map.draw
    @me.draw
    @my_shots.each {|shot| shot.draw}
    draw_player_names
    draw_you_lose unless @me.alive?
    draw_error_message if $error_message
    @other_shots.each_value {|shot| shot.draw}
    @other_tanks.each {|id, tank| tank.draw}
    @explosions.each {|exp| 
      exp.draw 
      add_to_messages('del', exp.uuid, 'explosion',  SpriteImage::Explosion, @player, exp.x, exp.y, 0.0)
    }
    @explosions.clear
  end

  def button_down(id)
    @me.shoot_toggle(button_down? KbSpace)
    close if id == KbEscape
  end

  def draw_player_names
    @font.draw("*#{@player} (#{@me.points})", 5, 0, 5, 1, 1, Gosu::Color::AQUA)
    @other_tanks.keys.each_with_index do |name, i|
      @font.draw("#{name} (#{@other_tanks[name].points})", 5, (i+1) * 20, 5)
    end
  end

  def draw_you_lose
    @font.draw("YOU WERE DESTROYED!", 150, (HEIGHT/2) - 20, 100, 2.1, 2.1)
  end

  def draw_error_message
    @font.draw($error_message, 150, (HEIGHT/2) - 20, 100, 1.6, 1.6, Gosu::Color::RED)
  end

  def random_position
    [rand(WIDTH), rand(HEIGHT)]
  end
end

server = ARGV[0] || SERVER
port = ARGV[1] || PORT
player = ARGV[2] || PLAYER_NAME
color = ARGV[3] || PLAYER_COLOR
game = GameWindow.new(server, port, player, color)
game.show
