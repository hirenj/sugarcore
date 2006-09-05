class CondensedLayout

  class << self

    def layout(sugar)
      do_initial_layout(sugar)
      do_box_layout(sugar)
    end

    def do_initial_layout(sugar)
        sugar.depth_first_traversal { |res|          
          y_offset = ( res.children.length - 1 ) * -10
          res.children.each { |link, residue|
            residue.move(res.position[:x2] + 10 ,y_offset + res.position[:y1])
            y_offset = y_offset + 20
#            link.position = { :x1 => res.position[:x1] + 9,
#                              :x2 => residue.position[:x1] + 1,
#                              :y1 => res.position[:y1] + 5,
#                              :y2 => residue.position[:y1] + 5 }.extend(Rectangle)
          }
        }
    end
    
    def do_box_layout(sugar)
      sugar.leaves.each { |residue|
        sugar.node_to_root_traversal(residue) { |res|
          if res.parent != nil
            res_box = res.box
            res.parent.children.each { |link, sibling|
              if sibling != res
                sib_box = sibling.box
                if (inter_box = calculate_intersection(sib_box, res_box)) != nil
                  spread_siblings(res.parent, inter_box.height)
                  sib_box = sibling.box
                  res_box = res.box
                end
              end 
            }
          end
        }
      }
      bunch_siblings(sugar,sugar.get_path_to_root[0])
    end

    def bunch_siblings(sugar,node)
      siblings = node.children.collect { |link, sibling|
        sibling
      }.sort_by{ |residue| node.distance(residue) }.each { |res|
        p sugar.sequence_from_residue(res)
      }
      midline = node.centre[:y]
      siblings.each { |sib|
        shift_towards_midline(sib, midline, siblings)
      }
    end

    def shift_towards_midline(node, midline, neighbs)
      midline_delta = node.centre[:y] - midline
      # Exponential backoff?
      # This is getting way too hard.
    end

    def do_spring_layout(sugar)
      while true
        
      end
    end

    def spread_siblings(node, delta)
      return if (delta == 0)
      kids = node.children.collect { |link, sibling| sibling }
#      above_kids = node.children.collect { |link, sibling| sibling }.delete_if { |res|
#        res.position[:y1] > 0
#      }.length
      above_kids = 1
      below_kids = node.children.collect { |link, sibling| sibling }.delete_if { |res|
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
#      node.children.each { |link, child|
#        link.position = { :x1 => node.position[:x1] + 9,
#                          :x2 => child.position[:x1] + 1,
#                          :y1 => node.position[:y1] + 5,
#                          :y2 => child.position[:y1] + 5 }.extend(Rectangle)
#      }
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
end