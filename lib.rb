require 'set'
require 'securerandom'

class Message
  attr :type, :data
  def initialize(type, data=nil)
    @type = type  # obj or del
    @data = data # missle object
  end

  def to_json(*a)
    {type: @type, data: @data.to_json}.to_json(*a)
  end
  
end

Sprite = Struct.new(:uuid, :type, :sprite, :player, :x, :y, :angle, :points, :color) do 
  def to_json(*a)
    Hash[self.each_pair.to_a]
  end  
end

class Store < Hash
  
  def get(uuid)
    self[uuid]
  end
  
  def add(obj)
    self[obj.uuid] = obj
    obj.uuid
  end
  
  def remove(uuid)
    self.delete(uuid)
  end
  
  def identify(obj)
    self.key(obj)
  end
end

class Pointer < Hash
  attr :store
  
  def initialize(store)
    @store = store
  end
  
  def tag(obj, tag)
    if self[tag].nil?
      self[tag] = Set.new
    end
    uuid = @store.add(obj)
    self[tag].add(uuid)
  end
  
  def detag(obj, tag)
    uuid = @store.identify(obj)
    self[tag].delete(uuid)
    @store.remove(uuid)
  end
  
  def get(tag)
    @store.values_at(*self[tag])
  end
end
