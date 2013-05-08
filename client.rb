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

  def send_message(json)
    @socket.write(json) if @socket
  end

  def read_message
    @socket.readpartial(4096) if @socket
  end

end

class GameWindow < Window

  attr_reader :spritesheet, :player, :map, :client

  def initialize(player, color)
    super(WIDTH, HEIGHT, false)
    self.caption = NAME
    @spritesheet = Image.load_tiles(self, SPRITESHEET, 33, 33, true)
    @map = Map.new(self, MAPFILE)  # map representing the movable area
    @client = Client.new(SERVER, PORT) # client that communicates with the server

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
    sprite = Sprite.new(uuid, sprite_type, sprite_image, player_name, x, y, angle, points, color)
    @messages << Message.new(message_type, sprite)
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
            exp = Explosion.new(self, tank.x, tank.y)
            @explosions << exp
            add_to_messages('obj', exp.uuid, 'explosion',  SpriteImage::Explosion, @player, exp.x, exp.y, 0.0)
          end
        end
      end
      # tell the server the bullet has moved
      add_to_messages('obj', shot.uuid, 'shot',  SpriteImage::Bullet, @player, shot.x, shot.y, shot.angle)
    end

    # send collected messages to the server
    @client.send_message @messages.to_json
    @messages.clear

    begin
      msg = @client.read_message
      data = JSON.parse msg

      tank_json = JSON.parse(data['tank'])
      tank_json.each do |tankdata|
        player = tankdata['player']
        unless player  == @player
          if @other_tanks[player]
            @other_tanks[player].points = tankdata['points']
            @other_tanks[player].warp_to(tankdata['x'], tankdata['y'], tankdata['angle'])
          else
            @other_tanks[player] = Tank.new(self, tankdata['sprite'], player, tankdata['x'], tankdata['y'], tankdata['angle'], tankdata['points'], tankdata['color'], tankdata['uuid'])
          end
        else
          @me.points = tankdata['points']
        end
      end

      shot_json = JSON.parse(data['shot'])
      shot_json.each do |shotdata|
        player = shotdata['player']
        unless player == @player
          if @other_shots[player]
            @other_shots[player].x, @other_shots[player].y, @other_shots[player].angle =  shotdata['x'], shotdata['y'], shotdata['angle']
          else
            @other_shots[player] = Shot.new(self, player, shotdata['x'], shotdata['y'], shotdata['angle'])
          end
        end
      end

      explosion_json = JSON.parse(data['explosion'])
      explosion_json.each do |expdata|
        @explosions << Explosion.new(self, expdata['x'], expdata['y'])
      end


    rescue Exception => e
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

game = GameWindow.new(PLAYER_NAME, PLAYER_COLOR)
game.show
