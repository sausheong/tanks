class Tank
  attr_reader :uuid, :player, :sprite_image, :x, :y, :angle, :points, :color

  def initialize(window, sprite_image, player, x, y, angle=0.0, points=10, color=0xffffffff, uuid=SecureRandom.uuid)
    @uuid = uuid
    @sprite_image = sprite_image
    @window, @player, @x, @y, @angle, @points = window, player, x, y, angle, points
    @vel_x = @vel_y = 0.0
    @color = color
  end

  def warp_to(x, y, angle=nil)
    @x, @y = x, y
    @angle = angle if angle
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end

  def accelerate
    @vel_x += offset_x(@angle, 0.5)
    @vel_y += offset_y(@angle, 0.5)
  end

  def move
    @x += @vel_x
    @y += @vel_y
    @vel_x *= 0.6
    @vel_y *= 0.6
  end

  def shoot
    if alive?
      shot = Shot.new(@window, @player, @x, @y, @angle.to_f)
      @window.add_shot shot
    end
  end

  def draw
    @window.spritesheet[@sprite_image].draw_rot(@x, @y, 1, @angle.to_f, 0.5, 0.5, 1, 1, @color) if alive?
  end

  def hit_wall?(map)
    return true if map.solid?(self.x - 16, self.y - 16) or  
    map.solid?(self.x + 16, self.y - 16) or 
    map.solid?(self.x - 16, self.y + 16) or  
    map.solid?(self.x + 16, self.y + 16) 
       
    return false   
  end

  def collide_with?(left, top, right, bottom)
    !(left > @x + 32 || right < @x  || top > @y + 32 || bottom < @y)
  end

  def hit
    @points -= 1
  end

  def alive?
    @points > 0
  end

  def points=(pts)
    @points = pts
  end

  def outside_battlefield?
    self.x - 16 < 0 or self.x + 16 > WIDTH or self.y - 16 < 0 or self.y + 16 > HEIGHT    
  end

end