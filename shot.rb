class Shot
  attr_accessor :sprite_image, :x, :y, :angle, :uuid

  def self.from_sprite(window, sprite)
    Shot.new(window, sprite[2], sprite[3], sprite[4], sprite[5], sprite[6], sprite[0])
  end

  def initialize(window, sprite_image, player, x, y, angle=0.0, uuid=SecureRandom.uuid)
    @uuid , @window, @sprite_image, @player, @x, @y, @angle = uuid, window, sprite_image.to_i, player, x.to_f, y.to_f, angle.to_f
  end

  def update
    @x += offset_x(@angle, 8)
    @y += offset_y(@angle, 8)
    
    if (@x > @window.width or @y > @window.height or @x < 0.0 or @y < 0.0 or @window.map.solid?(@x, @y))
      remove(self) 
    end    
  end

  def draw  
    @window.spritesheet[@sprite_image].draw_rot(@x, @y, 1, @angle.to_f)
  end  

  def remove(shot)    
    @window.remove_shot shot
  end

  def warp_to(x, y, angle=nil)
    @x, @y = x.to_f, y.to_f
    @angle = angle.to_f if angle
  end

end

class Explosion
  attr_accessor :sprite_image, :x, :y, :uuid

  def self.from_sprite(window, sprite)
    Explosion.new(window, sprite[4], sprite[5], sprite[0])
  end

  def initialize(window, sprite_image, x, y, uuid=SecureRandom.uuid) 
    @uuid, @window, @sprite_image, @x, @y = uuid, window, sprite_image.to_i, x.to_f, y.to_f
  end

  def draw  
    @window.spritesheet[@sprite_image].draw_rot(@x, @y, 1, 0.0)
  end  

end