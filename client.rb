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
    @me_shots = [] # a list of my shots

    @other_tanks = {} # hash of player names => tank objects (other than myself)
    @other_shots = {} # a hash of player names => shot objects in a hash (other than mine)
    
    @messages = [] # list of messages to send to the server at the end of each round

    # send message to let server know that this player has signed in
    add_to_message_queue('obj', @me)
    @server_sprite_uuids = []
    
  end
  
  # add a message to the queue to send to the server
  def add_to_message_queue(msg_type, obj)
    @messages << "#{msg_type}|#{obj.uuid}|#{obj.type}|#{obj.sprite_image}|#{obj.player}|#{obj.x}|#{obj.y}|#{obj.angle}|#{obj.points}|#{obj.color}"
  end

  def add_shot(shot)
    @me_shots << shot
    add_to_message_queue('obj', shot)
  end

  def move_tank
    @me.go(:left) and @me.accelerate and return if button_down? KbLeft
    @me.go(:right) and @me.accelerate and return if button_down? KbRight      
    @me.go(:up) and @me.accelerate and return if button_down? KbUp
    @me.go(:down) and @me.accelerate and return if button_down? KbDown    
  end

  def update
    begin
      # move the tank but store the previous location    
      move_tank
      px, py = @me.x, @me.y
      @me.move

      # don't overlap the wall or go outside of the battlefield
      @me.warp_to(px, py) if @me.hit_wall? or @me.outside_battlefield?

      # don't overlap another tank
      @other_tanks.each do |player, tank|
        @me.warp_to(px, py) if tank.alive? and @me.collide_with?(tank, 30)
      end

      # tell the server that the player has moved
      add_to_message_queue('obj', @me)    

      # move other people's shots, see if it hits me
      @other_shots.each do |player, shots|
        if @me.alive? 
          shots.each_value do |shot|
            if @me.collide_with?(shot, 16)
              @me.hit       
              add_to_message_queue('obj', @me)     
            end
          end
        end          
      end
      
      # move my shots and what happens when they move
      @me_shots.each do |shot|
        shot.update # move the bullet
        if shot.hit_wall? or shot.outside_battlefield?
          @me_shots.delete shot
          add_to_message_queue('del', shot)
        else
          add_to_message_queue('obj', shot)
        end
      end

      # send collected messages to the server
      @client.send_message @messages.join("\n")
      @messages.clear

      # read messages from the server
      if msg = @client.read_message
        @server_sprite_uuids.clear
        data = msg.split("\n")
        # create sprites or alter existing sprites from messages from the server
        data.each do |row|
          sprite = row.split("|")
          if sprite.size == 9
            player = sprite[3]
            @server_sprite_uuids << sprite[0]
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
                if !@other_shots[player]
                  @other_shots[player] = Hash.new
                end
                shot = Shot.from_sprite(self, sprite)
                @other_shots[player][shot.uuid] = shot
                shot.warp_to(sprite[4], sprite[5], sprite[6])                
              end
            end
          end # end check for sprite size
        end

        # remove other sprites not coming from the server
        @other_shots.each_value do |shots|
          shots.delete_if do |uuid, shot|
            !@server_sprite_uuids.include?(uuid)
          end
        end

        @other_tanks.delete_if do |user, tank|
          !@server_sprite_uuids.include?(tank.uuid)
        end

      end
    rescue Exception => e
      puts e.backtrace
    end

  end

  def draw
    @map.draw
    @me.draw
    @me_shots.each {|shot| shot.draw}
    draw_player_names
    draw_you_lose unless @me.alive?
    draw_error_message if $error_message
    @other_tanks.each_value {|tank| tank.draw}
    @other_shots.each_value do|shots| 
      shots.each_value {|shot| shot.draw}
    end
  end

  def button_down(id)
    @me.shoot if button_down? KbSpace
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
    [rand(32..WIDTH-32), rand(32..HEIGHT-32)]
  end
end

server = ARGV[0] || SERVER
port = ARGV[1] || PORT
player = ARGV[2] || PLAYER_NAME
color = ARGV[3] || PLAYER_COLOR
game = GameWindow.new(server, port.to_i, player, color)
game.show
