class Tank
  attr_reader :uuid, :sprite_image, :player, :x, :y, :angle, :points, :color

  def type
    self.class.name.downcase
  end

  def self.from_sprite(window, sprite)
    if sprite[0].length == 36
      Tank.new(window, sprite[2], sprite[3], sprite[4], sprite[5], sprite[6], sprite[7], sprite[8], sprite[0])
    end
  end

  def initialize(window, sprite_image, player, x, y, angle=0.0, points=10, color=0xffffffff, uuid=SecureRandom.uuid)
    @uuid = uuid
    @sprite_image = sprite_image.to_i
    @window, @player, @x, @y, @angle, @points, @color = window, player, x.to_f, y.to_f, angle.to_f, points.to_i, color.to_i
    @vel_x = @vel_y = 0.0
    @bang = Sample.new(window, "assets/bang.wav")
    @crash = Sample.new(window, "assets/crash.wav")
    @boom = Sample.new(window, "assets/boom.wav")
  end

  def warp_to(x, y, angle=nil)
    @x, @y = x.to_f, y.to_f
    @angle = angle.to_f if angle
  end

  def go(direction)
    @angle = case direction
    when :up then 0
    when :down then 180
    when :left then -90      
    when :right then 90
    end  
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
      shot = Shot.new(@window, SpriteImage::Bullet, @player, @x, @y, @angle.to_f)
      @window.add_shot shot
      @bang.play      
    end
  end

  def draw
    @window.spritesheet[@sprite_image].draw_rot(@x, @y, 1, @angle.to_f, 0.5, 0.5, 1, 1, @color) if alive?
  end

  def hit_wall?
    return true if @window.map.solid?(self.x - 16, self.y - 16) or
                   @window.map.solid?(self.x + 16, self.y - 16) or
                   @window.map.solid?(self.x - 16, self.y + 16) or
                   @window.map.solid?(self.x + 16, self.y + 16)
    return false
  end

  def collide_with?(obj, size)
    left, top, right, bottom = obj.x, obj.y, obj.x + size, obj.y + size
    !(left > @x + size || right < @x  || top > @y + size || bottom < @y)
  end

  def hit
    @points -= 1
    @crash.play
    @boom.play if @points == 0
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
