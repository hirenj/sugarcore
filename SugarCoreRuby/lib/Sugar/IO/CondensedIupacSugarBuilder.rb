# Condensed IUPAC-based builder
module CondensedIupacSugarBuilder

  def monosaccharide_factory(prototype)
      return Monosaccharide.Factory(NamespacedMonosaccharide,prototype)
  end
  
  def linkage_factory(prototype)
      return Linkage.Factory(CondensedIupacLinkageBuilder, prototype)
  end
  
	def parse_sequence(input_string)
		units = input_string.reverse.split(/([\]\[])/)
		units = units.collect { |unit| unit.reverse.split(/\)/).reverse }.flatten.compact
		root = monosaccharide_factory( units.shift )
		create_bold_tree(root,units)
		return root
	end
	
	def create_bold_tree(root_mono,unit_array)
		while unit_array.length > 0 do
			unit = unit_array.shift
			if ( unit == ']' )
				debug "Branching on #{root_mono.name}"
				child_info = create_bold_branch(unit_array)
				root_mono.add_child(child_info.shift,linkage_factory( child_info.shift))
			elsif ( unit == '[' )
				debug "Branch closed"
				return
			else
				child_info = unit.split(/\(/)
				root_mono = root_mono.add_child(monosaccharide_factory(child_info.shift),linkage_factory(child_info.shift))
			end
		end
	end
	
	def create_bold_branch(unit_array)
		unit = unit_array.shift
		child_info = unit.split(/\(/)
		mono = monosaccharide_factory(child_info.shift)
		linkage = child_info.shift
		create_bold_tree(mono,unit_array)
		return [mono,linkage]
	end
	
end

module CondensedIupacLinkageBuilder

  # TODO - Overwrite the set_first_residue method so that it sets the anomer in the residue
  attr :anomer

  def read_linkage(linkage_string)
  	if linkage_string =~ /([abu])([\d\?u])-([\d\?u])/
		result = {}
		@anomer = $1
		@first_position = $2.to_i
		@second_position = $3.to_i
		return result
  	else
  		raise MonosaccharideException.new("Linkage #{linkage_string} is not a valid linkage")
  	end    
  end
end