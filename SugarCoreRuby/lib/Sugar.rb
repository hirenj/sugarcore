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
  	def get_attachment_point_path_to_root(start_residue=@root)
  		if ( ! start_residue.parent )
  			return []
  		end
  		linkage = start_residue.linkage_at_position(1);
  		return [ linkage.get_position_for(linkage.get_paired_residue(start_residue)),
  				 get_attachment_point_path_to_root(start_residue.parent) ].flatten;
  	end

    # Subtract one sugar from the other, and return the difference. Assume both sugars are 
    # rooted at the same point (i.e. requiring no alignment)
    def subtract(sugar)
      this_sugar = self
      results = Array.new()
      visited = Hash.new()
      residue_comparator = lambda { |a, b|
        unless visited[a] && visited[b]
          if this_sugar.paths(a) != sugar.paths(b)
            results << sugar.sequence_from_residue(b)
            this_sugar.residue_composition(a).each { |res| 
              visited[res] = true
            }
            sugar.residue_composition(b).each { |res| 
              visited[res] = true
            }            
          end
        end
        true
      }
      compare_by_block(sugar, :breadth_first_traversal, &residue_comparator)
      puts results
    end

    # Run a comparator across the residues in a sugar, passing a block to use as a comparator, and optionally specifying a method
    # to use as a traverser. By default, a depth first traversal is performed.
    # The comparator block for residues is a simple true or false comparator, evaluating to true if the two
    # residues are the same, and false if they are different
    def compare_by_block(sugar, traverser=:depth_first_traversal)
      raise SugarException.new("No comparator block for residues provided") unless ( block_given? )
      raise SugarException.new("Traverser method does not belong to Sugar being compared") unless(
        respond_to?(traverser) && sugar.respond_to?(traverser)
      )
      myresidues = self.method(traverser).call()
      compresidues = sugar.method(traverser).call()
      sugars_equal = true
      while ! myresidues.empty? && ! compresidues.empty? && sugars_equal = yield(myresidues.shift, compresidues.shift)
      end
      return sugars_equal && myresidues.empty? && compresidues.empty?
    end


    # Search for a residue based upon a traversal using the linkage path.
    # FIXME - UNTESTED
    def find_residue_by_linkage_path(linkage_path)
    	loop_residue = @root
    	linkage_path.each{ |linkage_position|
			  warn "#{linkage_position}"
    		loop_residue = loop_residue.residue_at_position(linkage_position)
    	}
    	return loop_residue
    end

    # Depth first traversal of a sugar. If you pass an optional block to the method, you will visit
    # the residue and perform the block action on that node
    def depth_first_traversal(start_residue=@root)
       dfs = lambda { | start, children | 
        results = []
        if block_given?
          results.push(yield(start))
        else
          results.push(start)
        end
        children.each { |linkage_residue_tuple|
          residue = linkage_residue_tuple[1]
          results += dfs.call( residue, residue.children )
        }
        results
      }
      perform_traversal_with_algorithm(start_residue, &dfs)
    end

    # Breadth first traversal of a sugar. If you pass an optional block to the method, you will visit
    # the residue and perform the block action on that node
    def breadth_first_traversal(start_residue=@root)

      # Scoped variables and blocks - let's see you do this in Java! 
      queue = []
      results = []

      bfs = lambda { | start, children | 
        if block_given?
          results.push(yield(start))
        else
          results.push(start)
        end
        queue += children.collect { |link_res_tuple| link_res_tuple[1] }
        current = queue.shift
        if (current != nil)
          bfs.call( current, current.children )
        else
          results
        end
      }
      perform_traversal_with_algorithm(start_residue, &bfs)
      return results
    end

    # Perform a traversal of the sugar using a specified block to choose residues to
    # traverse over. If no block is given, a depth first search is performed
    def perform_traversal_with_algorithm(start_residue=@root)
      if block_given?
        results = []
        results += yield( start_residue, start_residue.children )
        return results        
      else
        return depth_first_traversal(start_residue)
      end
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
