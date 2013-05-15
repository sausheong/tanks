require 'celluloid/io'
require './lib'

class Arena
  include Celluloid::IO

  def initialize(host, port)
    puts "Starting Tanks Arena at #{host}:#{port}."
    @server = TCPServer.new(host, port)
    @sprites = Store.new
    @user_sprites = Pointer.new(@sprites)
    async.run
  end

  def finalizer
    @server.close if @server
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    user = "#{host}:#{port}"
    puts "#{user} has joined the arena."

    loop do

      data = socket.readpartial(4096)
      data_array = data.split("\n")
      if data_array and !data_array.empty?
        begin
          
          data_array.each do |row|            
            message = row.split("|")
            if message.size == 10
              case message[0] # first item in message is the action, rest is the sprite
              when 'obj'
                @sprites.add(message[1], message[1..9])
                @user_sprites.tag(message[1], user)
              
              when 'del'
                @sprites.remove message[1]
                @user_sprites.detag(message[1], user)
              end
            end
            response = String.new
            @user_sprites.tags.each do |tag|
              @user_sprites.get(tag).each do |obj|
                (response << obj.join("|") << "\n") if obj
              end
            end
            socket.write response          
            
          end
        rescue
          p $!
        end
      end # end data    
    end # end loop
  rescue EOFError => err
    sprite = @user_sprites.get("#{host}:#{port}").first
    puts "#{sprite[3]} has left arena."
    @sprites.remove(sprite[0])
    socket.close
  end
end

server, port = ARGV[0] || "0.0.0.0", ARGV[1] || 1234
supervisor = Arena.supervise(server, port.to_i)
trap("INT") do
  supervisor.terminate
  exit
end

sleep