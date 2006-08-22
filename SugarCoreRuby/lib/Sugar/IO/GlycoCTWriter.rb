module GlycoCTWriter
  include CondensedIupacSugarWriter
  
  def write_sequence(root_element)
    string_rep = ''
    res_count = 1
    root_element.residue_composition.each { |residue|
      if (residue.parent != nil)
        string_rep += "#{res_count}b:#{residue.anomer}-"
        string_rep += self.target_namespace ? residue.alternate_name(self.target_namespace) : residue.name()
        string_rep += "\n"
        res_count += 1
      end
    }
    string_rep
  end
  
end