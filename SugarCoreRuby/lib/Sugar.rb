require 'test/unit'
require "DebugLog"
require "Monosaccharide"

class Sugar
	#mixin Debugging tools
    include DebugLog
		
    def initialize(sequence)
        info "Input sequence is " + sequence
        @root = parse_bold_format(sequence)
    end
    
    def sequence_from_child(root_element)
        info "Creating sequence"
        string_rep = ''
        children = root_element.children.reverse
        first_child = children.shift
        if ( first_child )
	        string_rep += sequence_from_child(first_child[1]) + '(' + first_child[0].to_sequence + ')'
	    end
        children.reverse.each { |branch|
        	string_rep += '[' + sequence_from_child(branch[1]) + '(' + branch[0].to_sequence + ')]' 
        }
        string_rep += root_element.name
        return string_rep
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
        def parse_bold_format(input_string)
            units = input_string.reverse.split(/([\]\[])/)
            units = units.collect { |unit| unit.reverse.split(/\)/).reverse }.flatten.compact
            root = Monosaccharide.new(units.shift)
            create_bold_tree(root,units)
            return root
        end
        
        def create_bold_tree(root_mono,unit_array)
            while unit_array.length > 0 do
                unit = unit_array.shift
                if ( unit == ']' )
                    info "Branching on #{root_mono.name}"
                    child_info = create_bold_branch(unit_array)
                    root_mono.add_child(child_info.shift,child_info.shift)
                elsif ( unit == '[' )
                    info "Branch closed"
                    return
                else
                    child_info = unit.split(/\(/)
                    root_mono = root_mono.add_child(child_info.shift,child_info.shift)
                end
            end
        end
        
        def create_bold_branch(unit_array)
            unit = unit_array.shift
            child_info = unit.split(/\(/)
            mono = Monosaccharide.new(child_info.shift)
            linkage = child_info.shift
            create_bold_tree(mono,unit_array)
            return [mono,linkage]
        end
end

class TC_SugarTest < Test::Unit::TestCase
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
			sugar = Sugar.new('Man(a1-3)GalNAc')
		}
		
	end

	def test_composition
		assert_nothing_raised {
			sugar = Sugar.new('Man(a1-3)GalNAc')
			sugar.residue_composition()
			sugar.composition_of_residues('Man')
		}
	end
end

