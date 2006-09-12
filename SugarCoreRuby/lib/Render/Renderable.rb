module Rectangle
  def height
    self[:y2] - self[:y1]
  end
  
  def width
    self[:x2] - self[:x1]
  end
  
end

module Renderable
  
  attr_accessor :position, :prototype, :dimensions

  def centre
    { :x => ( position[:x1] + position[:x2] ) / 2 , :y => ( position[:y1] + position[:y2] ) / 2 }
  end

  def dimensions
    if ( @dimensions == nil )
      return { :width => 0, :height => 0}
    end
    return @dimensions
  end

  def width
    return position[:x2] - position[:x1]
  end

  def height    
    return position[:y2] - position[:y1]
  end

  def distance(other)
    p1 = centre
    p2 = other.centre
    Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
  end

  def position 
    if (@position == nil)
      @position = { :x1 => 0, :x2 => dimensions[:width], :y1 => 0, :y2 => dimensions[:height] }.extend(Rectangle)
    end
    return @position
  end

  def translate(deltax=0,deltay=0)
    move(deltax,deltay)
  end

  def move(deltax=0, deltay=0)
    position[:x1] = position[:x1] + deltax
    position[:x2] = position[:x2] + deltax
    position[:y1] = position[:y1] + deltay
    position[:y2] = position[:y2] + deltay
  end
  
end

module Renderable::Residue
  include Renderable
  
  attr_accessor :offsets
  
  def translate(deltax=0,deltay=0)
    move(deltax,deltay)
    children.each { |link, residue|
      residue.translate(deltax,deltay)
    }
  end
  
  def offset( linkage )
    if ( an_offset = offsets[linkage.get_position_for(self)] ) != nil
      return  an_offset
    end
    @offsets[0]
  end

  def offsets
    if ( @offsets == nil )
      return [{ :x => 0, :y => 0 }]
    end
    @offsets
  end

  def box
    # FIXME - This should be using Integer min and max values
    min_x = 100000
    min_y = 100000
    max_x = -100000
    max_y = -100000
    
    
    children.each { |link,child|
      link_box = link.get_paired_residue(self).box

      if link_box[:x1] < min_x
        min_x = link_box[:x1]
      end
      if link_box[:x2] > max_x
        max_x = link_box[:x2]
      end
      if link_box[:y1] < min_y
        min_y = link_box[:y1]
      end
      if link_box[:y2] > max_y
        max_y = link_box[:y2]
      end      
    }
    if position[:x1] < min_x
      min_x = position[:x1]
    end
    if position[:y1] < min_y
      min_y = position[:y1]
    end
    if position[:x2] > max_x
      max_x = position[:x2]
    end
    if position[:y2] > max_y
      max_y = position[:y2]
    end

    return { :x1 => min_x, :x2 => max_x, :y1 => min_y, :y2 => max_y }.extend(Rectangle)

  end
  
end

module Renderable::Link
  include Renderable
  
  def position
    left_residue = second_residue
    right_residue = first_residue

    if first_residue.position[:x1] < second_residue.position[:x2]
      left_residue = first_residue
      right_residue = second_residue
    end

    bottom_residue = second_residue
    top_residue = first_residue
    
    if first_residue.position[:y1] < second_residue.position[:y2]
      bottom_residue = first_residue
      top_residue = second_residue
    end

    result= { :x1 => left_residue.position[:x1] + left_residue.offset(self)[:x],
      :x2 => right_residue.position[:x1] + right_residue.offset(self)[:x],
      :y1 => bottom_residue.position[:y1] + bottom_residue.offset(self)[:y],
      :y2 => top_residue.position[:y1] + top_residue.offset(self)[:y],
    }.extend(Rectangle)
    if bottom_residue != left_residue
      result[:y1] = top_residue.position[:y1] + top_residue.offset(self)[:y]
      result[:y2] = bottom_residue.position[:y1] + bottom_residue.offset(self)[:y]
    end
    return result
  end

  def box
    # FIXME - This should be using Integer min and max values
    min_x = 100000
    min_y = 100000
    max_x = -100000
    max_y = -100000
    
    if position[:x1] < min_x
      min_x = position[:x1]
    end
    if position[:y1] < min_y
      min_y = position[:y1]
    end
    if position[:x2] > max_x
      max_x = position[:x2]
    end
    if position[:y2] > max_y
      max_y = position[:y2]
    end

    node = nil

    if first_residue.node_number > second_residue.node_number
      node = first_residue
    else
      node = second_residue
    end
    
    node_box = node.box
    
    if node_box[:x1] < min_x
      min_x = node_box[:x1]
    end
    if node_box[:x2] > max_x
      max_x = node_box[:x2]
    end
    if node_box[:y1] < min_y
      min_y = node_box[:y1]
    end
    if node_box[:y2] > max_y
      max_y = node_box[:y2]
    end
    
    return { :x1 => min_x, :x2 => max_x, :y1 => min_y, :y2 => max_y }.extend(Rectangle)

  end  

end

module Renderable::Sugar
  include Renderable
  
  def box
    @root.box
  end
end
