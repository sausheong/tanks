class Shot
  attr_accessor :x, :y, :angle, :uuid

  def initialize(window, player, x, y, angle=0.0)
    @uuid = SecureRandom.uuid
    @window, @player, @x, @y, @angle = window, player, x, y, angle
  end

  def update
    @x += offset_x(@angle, 8)
    @y += offset_y(@angle, 8)
    
    if (@x > @window.width or @y > @window.height or @x < 0.0 or @y < 0.0 or @window.map.solid?(@x, @y))
      remove(self) 
    end    
  end

  def draw  
    @window.spritesheet[SpriteImage::Bullet].draw_rot(@x, @y, 1, @angle.to_f)
  end  

  def remove(shot)    
    @window.remove_shot shot
  end

end

class Explosion
  attr_accessor :x, :y, :angle, :uuid

  def initialize(window, x, y)
    @uuid = SecureRandom.uuid
    @window, @x, @y = window, x, y
  end

  def draw  
    @window.spritesheet[SpriteImage::Explosion].draw_rot(@x, @y, 1, 0.0)
  end  

end