module CondensedIupacSugarWriter

	@@target_namespace = "http://glycosciences.de"

	def CondensedIupacSugarWriter.append_features(includingClass)
		
		super
		
		def includingClass.Target_Namespace=(ns)
			@@target_namespace = ns
		end

		def includingClass.Target_Namespace
			@target_namespace ? @target_namespace : @@target_namespace
		end

	end

	def target_namespace=(ns)
		@target_namespace = ns
	end

	def target_namespace
		@target_namespace ? @target_namespace : @@target_namespace
	end

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
        string_rep += self.target_namespace ? root_element.alternate_name(self.target_namespace) : root_element.name()
        return string_rep	
	end
end
