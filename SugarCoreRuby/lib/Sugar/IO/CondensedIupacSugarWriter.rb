module CondensedIupacSugarWriter
	def write_sequence(root_element)
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
end
