class CondensedLayout

  DEFAULT_NODE_DIMENSIONS = { :width => 100, :height => 100 }
  DEFAULT_NODE_SPACING = { :x => 300, :y => 100 }

  attr_accessor :node_dimensions
  attr_accessor :node_spacing

  def initialize()
    @node_dimensions = DEFAULT_NODE_DIMENSIONS
    @node_spacing = DEFAULT_NODE_SPACING
  end

  def layout(sugar)
    do_initial_layout(sugar)
    do_box_layout(sugar)
  end

  def do_initial_layout(sugar)
    sugar.depth_first_traversal { |res| 
      if ( res.dimensions[:width] == 0 && res.dimensions[:height] == 0 )
        res.dimensions = DEFAULT_NODE_DIMENSIONS
        res.position[:x2] = res.position[:x1] + res.dimensions[:width]
        res.position[:y2] = res.position[:y1] + res.dimensions[:height]
      end
      y_offset = ( 1 - res.children.length ) * node_spacing[:y]
      res.children.each { |child|
        child[:residue].move(res.position[:x2] + node_spacing[:x] ,y_offset + res.position[:y1])
        y_offset = y_offset + node_dimensions[:height] + node_spacing[:y]
      }
    }
  end
  
  def do_box_layout(sugar)
    sugar.leaves.each { |residue|
      sugar.node_to_root_traversal(residue) { |res|
        if res.parent != nil
          res_box = res.box
          res.parent.children.each { |child|
            if child[:residue] != res
              sib_box = child[:residue].box
              if (inter_box = calculate_intersection(sib_box, res_box)) != nil
                spread_siblings(res.parent, inter_box.height)
                sib_box = child[:residue].box
                res_box = res.box
              end
            end 
          }
        end
      }
    }
  end

  def spread_siblings(node, delta)
    return if (delta == 0)
    kids = node.children.collect { |child| child[:residue] }
    above_kids = 1
    below_kids = node.children.collect { |child| child[:residue] }.delete_if { |res|
      res.position[:y1] < 0
    }.length
    kids.each { |kid|
      if (kid.position[:y1] < 0)
        kid.translate(0,-1 * below_kids * delta)
        below_kids = below_kids - 1
      elsif (kid.position[:y1] > 0)
        kid.translate(0,delta * above_kids )
        above_kids = above_kids + 1
      end
    }
  end

  def calculate_intersection(rec1, rec2)
    if (rec1[:x1] < rec2[:x1])
      left_rec = rec1
      right_rec = rec2
    else
      left_rec = rec2
      right_rec = rec1
    end
    if (rec1[:y1] < rec2[:y1])
      bottom_rec = rec1
      top_rec = rec2
    else
      bottom_rec = rec2
      top_rec = rec1
    end
    
    contained_x = ( left_rec[:x2] > right_rec[:x2] )
    contained_y = ( bottom_rec[:y2] > top_rec[:y2] )
    
    intersected = { :x1 => right_rec[:x1],
                    :x2 => contained_x ? right_rec[:x2] : left_rec[:x2] ,
                    :y1 => top_rec[:y1],
                    :y2 => bottom_rec[:y2] }.extend(Rectangle)
#                      :y2 => contained_y ? top_rec[:y2] : bottom_rec[:y2] }
    
    if ((intersected[:x2] - intersected[:x1]) >= 0 && (intersected[:y2] - intersected[:y1]) >= 0)
      return intersected
    else
      return nil
    end
  end
end