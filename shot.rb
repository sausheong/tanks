class Shot
  attr_reader :uuid, :sprite_image, :player, :x, :y, :angle, :points, :color

  def type
    self.class.name.downcase
  end
  
  def self.from_sprite(window, sprite)
    Shot.new(window, sprite[2], sprite[3], sprite[4], sprite[5], sprite[6], sprite[0])
  end

  def initialize(window, sprite_image, player, x, y, angle=0.0, uuid=SecureRandom.uuid)
    @uuid , @window, @sprite_image, @player, @x, @y, @angle = uuid, window, sprite_image.to_i, player, x.to_f, y.to_f, angle.to_f
    @points, @color = 0, 0
  end

  def move
    @x += offset_x(@angle, 8)
    @y += offset_y(@angle, 8)
  end

  def draw  
    @window.spritesheet[@sprite_image].draw_rot(@x, @y, 1, @angle.to_f)
  end  

  def hit_wall?
    @window.map.solid?(@x, @y)
  end
  
  def outside_battlefield?
    self.x - 16 < 0 or self.x + 16 > WIDTH or self.y - 16 < 0 or self.y + 16 > HEIGHT
  end

  def warp_to(x, y, angle=nil)
    @x, @y = x.to_f, y.to_f
    @angle = angle.to_f if angle
  end

end
