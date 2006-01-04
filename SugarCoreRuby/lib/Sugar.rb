
require "DebugLog"
require "Monosaccharide"

class Sugar
    include DebugLog

    def initialize(sequence)
        info "Input sequence is " + sequence
        @root = parse_bold_format(sequence)
    end
    
    def sequence_from_child(root_element)
        info "Creating sequence"
        string_rep = ''
        children = root_element.children
        first_child = children.shift
        if ( first_child )
	        string_rep += sequence_from_child(first_child[1]) + '(' + first_child[0] + ')'
	    end
        children.reverse.each { |branch|
        	string_rep += '[' + sequence_from_child(branch[1]) + '(' + branch[0] + ')]' 
        }
        string_rep += root_element.name
        return string_rep
    end
    
    def composition
    	return @root.composition
    end
    
    def composition_of(name)
    	return composition().delete_if { |mono| 
    		mono.name != name
    	}
    end
    
    def sequence
    	sequence_from_child(@root)
    end
    
    def to_s
        return @root.to_s
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

#class TC_MonosaccharideTest < Test::Unit::TestCase
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
#end

