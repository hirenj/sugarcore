module CondensedIupacSugarWriter

	def CondensedIupacSugarWriter.append_features(includingClass)
		
		super
				
		@target_namespace = nil
		
		def includingClass.Target_Namespace=(ns)
			@target_namespace = ns
		end

		def includingClass.Target_Namespace
			@target_namespace
		end

	end

  def target_namespace=(ns)
    @target_namespace = ns
  end

	def target_namespace
	  return @target_namespace if (@target_namespace != nil)

	  return self.class.Target_Namespace() if (self.class.respond_to?(:Target_Namespace) && self.class.Target_Namespace != nil )
		  
	  return @root.class.Default_Namespace
	end

	def write_sequence(root_element)
    string_rep = ''
    children = root_element.children
    first_child = children.shift
    if ( first_child )
      first_child[0].extend(CondensedIupacLinkageWriter)
      string_rep += sequence_from_residue(first_child[1]) + '(' + first_child[0].to_sequence + ')'
    end
    children.reverse.each { |branch|
      branch[0].extend(CondensedIupacLinkageWriter)
      string_rep += '[' + sequence_from_residue(branch[1]) + '(' + branch[0].to_sequence + ')]' 
    }
    string_rep += self.target_namespace ? root_element.alternate_name(self.target_namespace) : root_element.name()
    return string_rep	
	end
end

module CondensedIupacLinkageWriter
  def to_sequence
    second_pos_string = second_position > 0 ? second_position : '?'
    first_pos_string = first_position > 0 ? first_position : '?'
		return "#{self.first_residue.anomer}#{first_pos_string}-#{second_pos_string}"
	end
end