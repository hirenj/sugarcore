require "Sugar"
require "set"
require 'DebugLog'

class Glycotransferase
	include DebugLog

  attr_accessor :substrate_pattern, :donor
  attr  :seen

  def Glycotransferase.Apply_Set(enzymes, sugar)
    sugarset = Array.new()
    seen_sugars = Set.new([ sugar.sequence ])
    sugarset << sugar
    added = true
    while added
      added = false
      enzymes.each { |enzyme|
        resultset = Array.new()
        resultset += sugarset
        sugarset.each { |sugar|
          if ( sugar.size < 20 )
            enzyme.acceptors(sugar)
            new_sugars = enzyme.apply_to_each_substrate(sugar)
            enzyme.acceptors(sugar)
            new_sugars.each { |sug|
              seq = sug.sequence
              if ! seen_sugars.include?( seq ) 
                seen_sugars << seq
                resultset << sug
              end
            }
          end
        }
        added = ( added || (resultset.size != sugarset.size))
        sugarset = resultset
      }
    end
    sugarset
  end

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
    apply_in_place(cloned)
    cloned
  end
  
  def apply_in_place(sugar,acceptor=nil)
    acceptors(sugar).find_all { |residue|
      if (acceptor)
        acceptor == residue
      else
        true
      end
    }.each { |residue|
      link = donor.deep_clone
      res = donor.first_residue.deep_clone
      link.set_first_residue(res)      
      if (residue.can_accept?(link))
        residue.add_child(res, link)
      end
    }
    sugar
  end

  def apply_to_each_substrate(sugar)
    if ( @seen[sugar] )
      debug "Applying enzyme to #{sugar.sequence} again for donor #{donor.first_residue.name}"
      return []
    else
      debug "Applying enzyme to #{sugar.sequence} for donor #{donor.first_residue.name}"
    end
    @seen[sugar] = true
    results = Array.new()
    acceptor_count = acceptors(sugar).length - 1
    (0..acceptor_count).each do
      target = sugar.deep_clone
      apply_in_place(target,acceptors(target)[results.length])
      results << target
    end
    results
  end
  
  def initialize()
    @seen = Hash.new()
  end
  
end
