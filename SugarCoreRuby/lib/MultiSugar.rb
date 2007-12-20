module Sugar::MultiResidue
  def can_accept?(linkage)
    true
  end

  def parent
    self.residue_at_position(@parent_position)[0]
  end

  def residue_at_position(attachment_position)
    if (attachment_position == @parent_position && attachment_position_consumed?(attachment_position) )
      return [ linkage_at_position(attachment_position).get_paired_residue(self) ]
    end
    kids = children.delete_if { |child| child[:link].get_position_for(self) != attachment_position }.collect { |child| child[:residue] }
    return kids
  end

  def paired_residue_position(attachment_position=@parent_position)
    if (linkage_at_position(attachment_position) == nil)
      return nil
    end
    linkage_at_position(attachment_position).get_position_for(residue_at_position(attachment_position)[0])
  end
  
  def add_child(mono,linkage)
    mono.residue_composition.each { |res|
      res.extend(Sugar::MultiResidue)
    }
    super(mono,linkage)
  end
end

module Sugar::MultiSugar

  def intersect(sugar,&block)
    matched = Hash.new()
    sugar.paths.each { |path|
      mypath = path.reverse
      path_follower = lambda { |residues, children|
        if residues.is_a? Monosaccharide
          residues = [ residues ]
        end
        test_residue = mypath.shift
        (residues || []).each { |residue|
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
        }
        [true]
      }
      perform_traversal_with_algorithm(&path_follower)
    }
    return matched.keys
  end
  
  def find_residue_by_linkage_path(linkage_path)
  	results = [@root]
  	while (linkage_path || []).size > 0
  	  linkage_position = linkage_path.shift
  	  results = results.collect { |loop_residue|
  	    loop_residue.residue_at_position(linkage_position)
  	  }.flatten
	  end
  	return results
  end
  
  def self.extend_object(sug)
    sug.residue_composition.each { |res|
      res.extend(Sugar::MultiResidue)
    }
    super
  end

end
