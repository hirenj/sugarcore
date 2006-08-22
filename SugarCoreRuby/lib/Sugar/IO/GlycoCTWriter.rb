module GlycoCTWriter
  include CondensedIupacSugarWriter
  
  def write_sequence(root_element)
    string_rep = ''
    root_element.residue_composition.each { |residue|
      if (residue.parent != nil)
        string_rep += residue.anomer + '-'
        string_rep += self.target_namespace ? residue.alternate_name(self.target_namespace) : residue.name()
        string_rep += "\n"
      end
    }
    string_rep
  end
  
end