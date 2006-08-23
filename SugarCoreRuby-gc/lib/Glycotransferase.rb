require "Sugar"

class Glycotransferase
  attr_accessor :substrate_pattern, :donor
  def acceptors(sugar)
    results = Array.new()
    sugar.depth_first_traversal { |residue|
      if substrate_pattern.name == residue.name
        residue
      end
    }.compact
  end
  
  def accepted_on?(sugar)
    acceptors(sugar).length > 0
  end
  
  def apply(sugar)
    cloned = sugar.clone
    puts cloned.object_id
    puts cloned.root.object_id
    puts sugar.root.object_id
  end
  
  def apply!(sugar)
    acceptors(sugar).each { |residue|
      link = donor.clone
      res = link.first_residue.clone
      link.set_first_residue(res)
      if (residue.can_accept?(link))
        residue.add_child(res, link)
      end
    }
    sugar
  end
end
