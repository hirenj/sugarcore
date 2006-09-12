require "DebugLog"
require "Monosaccharide"

# Default implementation of a reader and writer for sugar sequences
module DefaultReaderWriter
        
    # Any mixins for reading sequences must overwrite this method
    def parse_sequence(sequence)
      raise SugarException.new("Could not parse sequence. Perhaps you haven't added parsing capability to this sugar")
    end

    # Any mixins for reading sequences must overwrite this method
    def write_sequence(sequence)
      raise SugarException.new("Could not write sequence. Perhaps you haven't added writing capability to this sugar")
    end

end

# Sugar class for representing sugars for various bioinformatic manipulations
class Sugar
	  #mixin Debugging tools
    include DebugLog
    include DefaultReaderWriter

    attr :root
    attr_accessor :name

		def finish
		  if (@root != nil)
		    @root.finish
		    @root = nil
	    end
	  end
		
    def deep_clone
      cloned = self.dup
      cloned.initialize_from_copy(self)
      cloned
    end

		def initialize_from_copy(original)
		  @root = original.get_path_to_root[0].deep_clone
	  end
	  
    # Set the sequence for this sugar. The Sugar must be able to 
    # parse this sequence (done by extending the Sugar), otherwise
    # it will raise a SugarException
    def sequence=(seq)
    	if (@root != nil)
    		finish
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
    
    def size(start_residue=@root)
      return residue_composition(start_residue).size
    end
    
    # Find the residues which comprise this sugar that match a particular prototype
    def composition_of_residue(prototype,start_residue=@root)
      if (prototype.class == String)
        prototype = Monosaccharide.Factory( @root.class, prototype )
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
      node_to_root_traversal(start_residue)
  	end

    # The linkage position path from the specified residue to the root.
  	def get_attachment_point_path_to_root(start_residue=@root)
  		if ( ! start_residue.parent )
  			return []
  		end
  		linkage = start_residue.linkage_at_position();
  		return [ linkage.get_position_for(linkage.get_paired_residue(start_residue)),
  				 get_attachment_point_path_to_root(start_residue.parent) ].flatten;
  	end

    # Calculate the intersection of two sugars aligned together at the root
    # returns the residues which have matched up with the given sugar
    def intersect(sugar)
      matched = Hash.new()
      sugar.paths.each { |path|
        mypath = path.reverse
        path_follower = lambda { |residue, children|
          if residue 
            test_residue = mypath.shift
            if (residue.name == test_residue.name)
              matched[residue] = true
            end
            if (mypath[0])
              path_follower.call(residue.residue_at_position(mypath[0].paired_residue_position()), nil)
            end
          end
          [true]
        }
        perform_traversal_with_algorithm(&path_follower)
      }
      return matched.keys
    end

    # Subtract the given sugar from this sugar. Returns a list of residues which exist in this sugar, but do
    # not exist in the sugar given as an argument
    def subtract(sugar)
      matched = intersect(sugar)
      results = Array.new()
      leaves.each { |leaf|
        node_to_root_traversal(leaf) { |residue|
          if ! matched.include?(residue) && ! results.include?(residue)
            results << residue
          end
          if matched.include?(residue.parent)
            raise SugarTraversalBreakSignal.new()
          end
        }
      }
      results
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
          begin
            results = []
            if block_given?
              results.push(yield(start))
            else
              results.push(start)
            end
            children.each { |link, residue|
              results += dfs.call( residue, residue.children )
            }
            results
          rescue SugarTraversalBreakSignal
            results
          end
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
        begin
          if block_given?
            results.push(yield(start))
          else
            results.push(start)
          end
          queue += children.collect { |link, residue| residue }
          current = queue.shift
          if (current != nil)
            bfs.call( current, current.children )
          else
            results
          end
        rescue SugarTraversalBreakSignal
          results
        end
      }
      perform_traversal_with_algorithm(start_residue, &bfs)
      return results
    end
    
    # Traverse the sugar from a given node to the root of the structure. If you pass an optional
    # block to the method, you will visit the residue and perform the block action on that node
    def node_to_root_traversal(start_residue)
      results = Array.new()
      root_traversal = lambda { | start, children |
        begin
          if block_given?
            results.push(yield(start))
          else
            results.push(start)
          end
          if (start.parent)
            root_traversal.call( start.parent, nil )
          else
            results
          end
        rescue SugarTraversalBreakSignal
          results
        end
      }
      perform_traversal_with_algorithm(start_residue, &root_traversal)
      return results
    end

    # Perform a traversal of the sugar using a specified block to choose residues to
    # traverse over. If no block is given, a depth first search is performed
    # FIXME - This should work a bit more like collect
    def perform_traversal_with_algorithm(start_residue=@root)
      if block_given?
        results = []
        results += yield( start_residue, start_residue.children )
        return results        
      else
        return depth_first_traversal(start_residue)
      end
    end

end
