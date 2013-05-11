require 'set'
require 'securerandom'

Sprite = Struct.new(:uuid, :type, :sprite_image, :player, :x, :y, :angle, :points, :color) do 
  def to_msg
    to_a.join("|")
  end  
end

class Store < Hash
  
  def get(uuid)
    self[uuid]
  end
  
  def add(uuid, obj)
    self[uuid] = obj
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
  
  def tag(uuid, tag)
    if self[tag].nil?
      self[tag] = Set.new
    end
    self[tag].add(uuid)
  end
  
  def detag(uuid, tag)
    self[tag].delete(uuid)
  end
  
  def get(tag)
    @store.values_at(*self[tag])
  end
  
  def tags
    self.keys
  end
  
end
