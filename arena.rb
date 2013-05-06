require 'celluloid/io'
require 'json'
require './lib'

class Arena
  include Celluloid::IO

  def initialize(host, port)
    puts "Starting Arena."
    @server = TCPServer.new(host, port)
    @store = Store.new
    @pointer = Pointer.new(@store)
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
    puts "#{host}:#{port} has joined the arena."
    loop do
      json = socket.readpartial(4096)
      if json and !json.empty?
        begin
          messages = JSON.parse(json)
          messages.each do |message|

            data = message['data']
            case message['type']
            when 'obj'
              sprite = @store.get data['uuid']
              if sprite.nil?
                sprite = Sprite.new *data.values

                @pointer.tag sprite, data['type']
                @pointer.tag sprite, "#{host}:#{port}"
              else
                %w(x y angle ).each do |prop|
                  sprite[prop] = data[prop]
                end

                if sprite['type'] == 'tank' and sprite['points'] > data['points']
                  sprite['points'] = data['points']
                end
              end            
            when 'del'
              @store.remove data['uuid']
            end
            response = {}
            %w(tank shot explosion).each do |type|
              json_array = @pointer.get(type).map do |sprite|
                sprite.to_json if sprite
              end
              response[type] = json_array.compact.to_json 
            end        
            socket.write response.to_json          
          
          end
        rescue

        end
      end # end json
      
    end # end loop

  rescue EOFError => err
    puts "#{host}:#{port} has left the arena."
    sprite = @pointer.get("#{host}:#{port}").first
    puts "Removing #{sprite['player']} from arena."
    @store.remove sprite['uuid']
    socket.close
  end
end

supervisor = Arena.supervise("0.0.0.0", 1234)
trap("INT") do
  supervisor.terminate
  exit
end

sleep