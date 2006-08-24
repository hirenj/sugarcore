require "Sugar"

class Glycotransferase
  attr_accessor :substrate_pattern, :donor
  def acceptors(sugar)
    results = Array.new()
    sugar.depth_first_traversal { |residue|
      if substrate_pattern.name == residue.name && residue.can_accept?(donor)
        residue
      end
    }.compact
  end
  
  def accepted_on?(sugar)
    acceptors(sugar).length > 0
  end
  
  def apply(sugar)
    cloned = sugar.deep_clone
    apply!(cloned)
    cloned
  end
  
  def apply!(sugar,acceptor=nil)
    acceptors(sugar).find_all { |residue|
      if (acceptor)
        acceptor == residue
      else
        true
      end
    }.each { |residue|
      link = donor.clone
      res = link.first_residue.clone
      link.set_first_residue(res)
      if (residue.can_accept?(link))
        residue.add_child(res, link)
      end
    }
    sugar
  end
  
  def apply_to_each_substrate(sugar)
    results = Array.new()
    acceptor_count = acceptors(sugar).length - 1
    (0..acceptor_count).each do
      target = sugar.dup
      apply!(target,acceptors(target)[results.length])
      results << target
    end
    results
  end
end
