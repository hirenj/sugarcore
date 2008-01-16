require "DebugLog"
require "Monosaccharide"

# Default implementation of a reader and writer for sugar sequences
# This is automatically added to all Sugar objects
module DefaultReaderWriter

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

# Sugar class for representing sugars for various bioinformatic manipulations
# Since there are circular references within objects, it is very important to 
# finish off all sugars once you are finished with them by calling the finish()
# method.
#   sug = Sugar.new
#   sug.sequence = 'Gal(b1-3)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc'
#   sug.residue_composition                           # [Gal,GlcNAc,GlcNAc]
#   sug.size                                          # 3
#   sug.breadth_first_traversal { |res| p res.name }  # GlcNAc, GlcNAc, Fuc, Gal
#   sug.depth_first_traversal { |res| p res.name }    # GlcNAc, GlcNAc, Gal, Fuc
#   sug.finish
class Sugar
	  #mixin Debugging tools
    include DebugLog
    include DefaultReaderWriter

    attr :root
    attr_accessor :name

    # Finish this sugar by breaking any cyclical references
		def finish
		  if (@root != nil)
		    @root.finish
		    @root = nil
	    end
	  end
		
		# Perform a deep cloning of this sugar - equivalent to creating another 
		# sugar with the same sequence
    def deep_clone
      cloned = self.dup
      cloned.initialize_from_copy(self)
      cloned
    end

		def initialize_from_copy(original)
		  @root = original.get_path_to_root[0].deep_clone
	  end
	  
	  protected :initialize_from_copy

    def eql?(o)
      o.is_a?(Sugar) && sequence == o.sequence
    end
    
    def hash
      self.sequence
    end
	  
    # Set the sequence for this sugar. The Sugar must be able to 
    # parse this sequence (done by extending the Sugar), otherwise
    # it will raise a SugarException
    #   sug = Sugar.new()
    #   sug.sequence = 'Gal(b1-3)GlcNAc'    # SugarException => "Could not parse sequence"
    #   sug.extend(Sugar::IO::CondensedIupac::Builder)
    #   sug.sequence = 'Gal(b1-3)GlcNAc'
    #   sug.size                            # 2
    def sequence=(seq)
    	if (@root != nil)
    		finish
    	end
      debug "Input sequence is " + seq
      begin
        @root = parse_sequence(seq)        
      rescue Exception => e
        error "Could not parse the sequence, setting root to nil:\n#{seq}\n\n#{e}"
        @root = nil
        raise SugarException.new("Could not parse the sequence, setting root to nil:\n#{seq}\n\nBase cause: #{e}")
      end      
    end
    
    # Compute the sequence for this sugar. This method is an alias for computing 
    # sequence_from_residue() with a start_residue of root.
    #     sug = Sugar.new()
    #     sug.sequence            # nil
    def sequence
    	sequence_from_residue(@root)
    end
    
    # Create a Sugar object based upon an array of Linkages passed to it. The first
    # linkage in the array will define the root of the Sugar. Will destroy all objects
    # related to the current sugar
    # Doesn't work for more than one linkage at the moment. How do you figure out
    # if the linkages are not from disconnected graphs
    def linkages=(linkages)
      self.finish
      new_residues = Hash.new() { |h,k| h[k] = k.shallow_clone }
      linkages.each { |link|
        parent = new_residues[link[:link].get_paired_residue(link[:residue])]
        child = new_residues[link[:residue]]
        if @root == nil
          @root = parent
        end
        parent.add_child(child,link[:link].deep_clone)
      }
    end
    
    def linkages(start_residue=@root)
      return residue_composition(start_residue).collect { |r| r.linkage_at_position }
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
    	return start_residue ? start_residue.residue_composition : []
    end
    
    def size(start_residue=@root)
      return residue_composition(start_residue).size
    end
    
    # Find the residues which comprise this sugar that match a particular prototype
    def composition_of_residue(prototype,start_residue=@root)
      if (prototype.class == String)
        prototype = monosaccharide_factory( prototype )
      end
    	return residue_composition(start_residue).reject { |m|
    	  m.name != prototype.name
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

    def get_sugar_to_root(start_residue=@root)
      new_sugar = self.class.new()
      residues = get_path_to_root(start_residue).reverse
      residues.shift
      new_sugar.linkages = residues.collect { |r| { :link => r.linkage_at_position, :residue => r } }
      new_sugar
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
    def intersect(sugar,&block)
      matched = Hash.new()
      sugar.paths.each { |path|
        mypath = path.reverse
        path_follower = lambda { |residue, children|
          if residue
            test_residue = mypath.shift
            if block_given?
               if yield(residue, test_residue)
                 matched[residue] = true
               end
            else
              if residue.name(:id) == test_residue.name(:id) && residue.anomer == test_residue.anomer
                matched[residue] = true
              end
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
    def subtract(sugar, &block)
      matched = self.intersect(sugar,&block)
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

    def union(sugar, &block)
      new_sug = self.deep_clone
      new_sug.union!(sugar,&block)
      return new_sug
    end

    def union!(sugar, &block)
      matched_sugar = sugar.subtract(self)
      if block_given?
        self.intersect(sugar).each { |res|
          yield res
        }
      end
      matched_sugar = matched_sugar.delete_if { |res| matched_sugar.include? res.parent }
      (matched_sugar).each { |res|
        path = sugar.get_attachment_point_path_to_root(res.parent).reverse
        attachment_res = self.find_residue_by_linkage_path(path)
        new_res = res.deep_clone
        if attachment_res.is_a? Array
          attachment_res = attachment_res.delete_if { |m_res|
            (m_res.name(:id) != res.parent.name(:id)) || (m_res.anomer != res.parent.anomer)
          }.first
        end
        attachment_res.add_child(new_res,res.linkage_at_position.deep_clone)
      }      
      return self
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
    	
    	(linkage_path || []).each{ |linkage_position|
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
            children.each { |child|
              results += dfs.call( child[:residue], child[:residue].children )
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
          queue += children.collect { |child| child[:residue] }
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
