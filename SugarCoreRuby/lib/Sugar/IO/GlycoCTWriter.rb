require 'Sugar/IO/CondensedIupacSugarWriter'

module GlycoCTWriter
  
  def write_sequence(root_element)
    string_rep = "RES\n"
    residues = Hash.new()
    links = Hash.new()
    self.residue_composition(root_element).each { |residue|
      names = residue.alternate_name(NamespacedMonosaccharide::ECDB_NAMESPACE).scan(/(\w+)(?:\|(\d+)(\w+))*/).shift
      residues[residue] = "b:#{residue.anomer || 'u'}-#{names.shift};\n"
      while names.length > 1 && names[0] != nil
        pos = names.shift
        substituent = names.shift
        residues[substituent] = "s:#{substituent};\n"
        if ( ! links[residue] )
          links[residue] = Hash.new()            
        end
        links[residue][pos] = substituent
      end
    }
    counter = 1
    residues.keys.sort_by { |el| el.is_a?(String) ? '2'+el : el.parent == nil ? '00' : '1'+residues[el]+get_attachment_point_path_to_root(el).join(',') }.each { |res|
      string_rep += "#{counter}#{residues[res]}"
      residues[res] = counter
      counter = counter + 1
    }
    
    string_rep += "LIN\n"
    counter = 1
    self.breadth_first_traversal(root_element) { |res| 
      res.children.collect { |kid| kid[:link] }.each { |link|
        red_residue = link.reducing_end_substituted_residue
        opp_residue = link.get_paired_residue(red_residue)
        string_rep += "#{counter}:#{residues[opp_residue]}(#{write_linkage(link.get_position_for(opp_residue))}-#{write_linkage(link.get_position_for(red_residue))})#{residues[red_residue]};\n"
        counter = counter + 1
      }
    }
    links.keys.sort_by { |res| residues[res] }.each { |res|
      links[res].each { |posn, sub|
        string_rep += "#{counter}:#{residues[res]}o(#{posn}-1)#{residues[sub]};\n"
        counter = counter + 1
      }
    }
    string_rep
  end
  
  def write_linkage(position)
    if (position > 0)
      position.to_s
    else
      'u'
    end
  end
  
  private :write_linkage
  
end