module Rectangle
  def height
    self[:y2] - self[:y1]
  end
  
  def width
    self[:x2] - self[:x1]
  end
  
end

module Renderable

  attr_accessor :position, :prototype, :node_number

  def position 
    if self.kind_of? Linkage
      position_linkage
    end
    if (@position == nil)
      @position = { :x1 => 0, :x2 => 10, :y1 => 0, :y2 => 10 }.extend(Rectangle)
    end
    @position
  end

  def move(deltax=0, deltay=0)
    position[:x1] = position[:x1] + deltax
    position[:x2] = position[:x2] + deltax
    position[:y1] = position[:y1] + deltay
    position[:y2] = position[:y2] + deltay
  end
  
  def translate(deltax=0,deltay=0)
    move(deltax,deltay)
    children.each { |link, residue|
      link.move(deltax,deltay)
      residue.translate(deltax,deltay)
    }
  end

  def centre
    { :x => ( position[:x1] + position[:x2] ) / 2 , :y => ( position[:y1] + position[:y2] ) / 2 }
  end

  def distance(other)
    p1 = centre
    p2 = other.centre
    Math.sqrt((p1[:x] - p2[:x])**2 + (p1[:y] - p2[:y])**2)
  end

  def box
    if self.kind_of? Sugar
      box_sugar
    elsif self.kind_of? Monosaccharide
      box_monosaccharide
    elsif self.kind_of? Linkage
      box_linkage
    end
  end
  
  private
  
  def position_linkage
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
    
    { :x1 => left_residue.position[:x1] + 5,
      :x2 => right_residue.position[:x1] + 5,
      :y1 => bottom_residue.position[:y1] + 5,
      :y2 => top_residue.position[:y1] + 5,
    }.extend(Rectangle)
  end
  
  def box_sugar
    @root.box
  end

  def box_monosaccharide
    
    min_x = 1000
    min_y = 1000
    max_x = -1000
    max_y = -1000
    
    
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
  
  def box_linkage

    min_x = 1000
    min_y = 1000
    max_x = -1000
    max_y = -999
    
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