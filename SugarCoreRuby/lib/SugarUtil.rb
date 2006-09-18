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
    all_links = Hash.new()
    residues.each { |res|
      res.children.each { |link,res|
        link.extend(LinkageWriter)
        if ! all_links.include?(link.to_sequence)
          all_links[link.to_sequence] = Array.new()
        end
        all_links[link.to_sequence].push( link )
      }
    }
    return all_links
  end
end