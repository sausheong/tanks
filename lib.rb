require 'set'
require 'securerandom'


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
