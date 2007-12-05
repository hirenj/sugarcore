require 'Sugar'

module LinkageWriter
  def to_sequence
    second_pos_string = second_position > 0 ? second_position : '?'
    first_pos_string = first_position > 0 ? first_position : '?'
		return "#{first_residue.alternate_name('http://glycosciences.de')}(#{self.first_residue.anomer}#{first_pos_string}-#{second_pos_string})#{second_residue.alternate_name('http://glycosciences.de')}"
	end
end

class SugarUtil
  def self.FindDisaccharides(sugar)
    residues = sugar.residue_composition
    all_links = Hash.new() { |h,k| h[k] = Array.new() }
    residues.each { |res|
      res.children.each { |kid|
        new_sug = sugar.class.new()
        new_sug.linkages = [ kid ]
        all_links[new_sug].push( kid[:link] )
      }
    }
    return all_links
  end
  def self.SugarFromDisaccharide(sugar,child)
    new_linkage = { :link => child.linkage_at_position, :residue => child }
    new_sug = sugar.class.new()
    new_sug.linkages = [ new_linkage ]
    return new_sug
  end
end