require 'test/unit'
require "DebugLog"
require "Monosaccharide"

class Sugar
	#mixin Debugging tools
    include DebugLog
		
    def initialize()
	end
    
    def sequence=(seq)
    	if (@root)
    		@root.finish()
    		@root = nil
    	end
        debug "Input sequence is " + seq
        @root = parse_sequence(seq)
    end
    
    
    def sequence_from_child(root_element)
        debug "Creating sequence"
		write_sequence(root_element)
    end
    
    def residue_composition(start_residue=@root)
    	return start_residue.residue_composition
    end
    
    def composition_of_residues(name)
    	return residue_composition().delete_if { |mono| 
    		mono.name != name
    	}
    end
    
    def sequence
    	sequence_from_child(@root)
    end
    
    def to_s
        return @root.to_s
    end
    
    def paths
    	return get_leaves(@root).map{ |leaf|
    		leaf.get_path_to_root()
    	}
    end
    
    def get_leaves(start_residue=@root)
		return residue_composition(start_residue).delete_if { |residue|
			residue.children.length != 0
		}    	
    end
    
    def subtract(sugar)
    	return sugar.get_leaves().map { |leaf|
    		self.sequence_from_child(
    			find_residue_by_linkage_path(
    				leaf.get_attachment_point_path_to_root().reverse()
    			)
    		)
    	}
    end
    
    def find_residue_by_linkage_path(linkage_path)
    	loop_residue = @root
    	linkage_path.each{ |linkage_position|
			warn linkage_position
    		loop_residue = loop_residue.get_residue_at_position(linkage_position)
    	}
    	return loop_residue
    end
    
    private
end

class TC_SugarTest < Test::Unit::TestCase
	require 'Sugar/IO/CondensedIupacSugarBuilder'
	require 'Sugar/IO/CondensedIupacSugarWriter'

#
#  def test_initialisation
#
#    assert_nothing_raised {
#        sugar = Sugar.new('Hij(b1-3)Efg(b1-3)[Nop(a1-2)[Mno(a1-3)][Jkl(b1-4)]Cde(b1-4)]Bcd(b1-3)Abc')
#        puts sugar.to_s
#    }
#    assert_raises( Password::WeakPassword ) { pw.check }
#  
#  end
#
	def test_sequences
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
			sugar.sequence = 'Man(a1-3)GalNAc'
		}
		
	end

	def test_composition
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
			sugar.sequence = 'Man(a1-3)GalNAc'
			sugar.residue_composition()
			sugar.composition_of_residues('Man')
		}
	end
end

