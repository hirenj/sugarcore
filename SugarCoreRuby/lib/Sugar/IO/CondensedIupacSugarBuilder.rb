# Condensed IUPAC-based builder
module CondensedIupacSugarBuilder
  def Monosaccharide_Class
      return Namespaced_Monosaccharide
  end

	def parse_sequence(input_string)
		units = input_string.reverse.split(/([\]\[])/)
		units = units.collect { |unit| unit.reverse.split(/\)/).reverse }.flatten.compact
		root = Monosaccharide.factory( self.Monosaccharide_Class, units.shift )
		create_bold_tree(root,units)
		return root
	end
	
	def create_bold_tree(root_mono,unit_array)
		while unit_array.length > 0 do
			unit = unit_array.shift
			if ( unit == ']' )
				debug "Branching on #{root_mono.name}"
				child_info = create_bold_branch(unit_array)
				root_mono.add_child(child_info.shift,child_info.shift)
			elsif ( unit == '[' )
				debug "Branch closed"
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
		mono = Monosaccharide.factory( self.Monosaccharide_Class, child_info.shift)
		linkage = child_info.shift
		create_bold_tree(mono,unit_array)
		return [mono,linkage]
	end
end
