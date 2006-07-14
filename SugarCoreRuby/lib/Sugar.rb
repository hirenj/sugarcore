require "DebugLog"
require "Monosaccharide"

# Sugar class for representing sugars for various bioinformatic manipulations
class Sugar
	  #mixin Debugging tools
    include DebugLog
		
    # Set the sequence for this sugar. The Sugar must be able to 
    # parse this sequence (done by extending the Sugar), otherwise
    # it will raise a SugarException
    def sequence=(seq)
    	if (@root)
    		@root.finish()
    		@root = nil
    	end
      debug "Input sequence is " + seq
      @root = parse_sequence(seq)
    end
    
    # Compute the sequence for this sugar. This method is an alias for computing 
    # sequence_from_child() with a start_residue of root.
    def sequence
    	sequence_from_residue(@root)
    end
    
    # Compute the sequence for this sugar from a particular start residue.
    # If no residue is specified, the sequence is calculated from the root 
    # of the sugar.
    def sequence_from_residue(start_residue=@root)
      debug "Creating sequence"
		  write_sequence(start_residue)
    end
    
    # Find the residue composition of this sugar
    def residue_composition(start_residue=@root)
    	return start_residue.residue_composition
    end
    
    # Find the residues which comprise this sugar that match a particular prototype
    def composition_of_residue(prototype,start_residue=@root)
      if (prototype.class == String)
        prototype = Monosaccharide.factory( @root.class, prototype )
      end
    	return residue_composition(start_residue).delete_if { |mono| 
    		mono.name != prototype.name
    	}
    end    
    
    # Return a string representation of this sugar
    def to_s
        return @root.to_s
    end
    
    # Find the paths from the leaves in this sugar to the root
    def paths(start_residue=@root)
    	return leaves(start_residue).map{ |leaf|
    		get_path_to_root(leaf)
    	}
    end
    
    # List the leaf elements of this sugar - any residues which don't have 
    # any child residues
    def leaves(start_residue=@root)
  		return residue_composition(start_residue).delete_if { |residue|
  			residue.children.length != 0
  		}    	
    end

    # The path to the root residue from the specified residue
  	def get_path_to_root(start_residue=@root)
  		if ( ! start_residue.parent )
  			return [ start_residue ]
  		end
  		return [ start_residue , get_path_to_root(start_residue.parent) ].flatten
  	end

    # The linkage position path from the specified residue to the root.
  	def get_attachment_point_path_to_root(start_reside=@root)
  		if ( ! start_residue.parent )
  			return []
  		end
  		linkage = start_residue.linkage_at_position(1);
  		return [ linkage.get_position_for(linkage.get_paired_residue(start_residue)),
  				 get_attachment_point_path_to_root(start_residue.parent) ].flatten;
  	end

    # Subtract one sugar from the other, and return the difference
    def subtract(sugar)
    	return sugar.get_leaves().map { |leaf|
    		self.sequence_from_child(
    			find_residue_by_linkage_path(
    				leaf.get_attachment_point_path_to_root().reverse()
    			)
    		)
    	}
    end

    # Search for a residue based upon a traversal using the linkage path.
    def find_residue_by_linkage_path(linkage_path)
    	loop_residue = @root
    	linkage_path.each{ |linkage_position|
			warn linkage_position
    		loop_residue = loop_residue.get_residue_at_position(linkage_position)
    	}
    	return loop_residue
    end
    
    protected
    
    # Any mixins for reading sequences must overwrite this method
    def parse_sequence(sequence)
      raise SugarException.new("Could not parse sequence. Perhaps you haven't added parsing capability to this sugar")
    end

    # Any mixins for reading sequences must overwrite this method
    def write_sequence(sequence)
      raise SugarException.new("Could not write sequence. Perhaps you haven't added writing capability to this sugar")
    end

end
