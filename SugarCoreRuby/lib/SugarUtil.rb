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
      res.children.each { |kid|
        kid[:link].extend(LinkageWriter)
        if ! all_links.include?(kid[:link].to_sequence)
          all_links[kid[:link].to_sequence] = Array.new()
        end
        all_links[kid[:link].to_sequence].push( kid[:link] )
      }
    }
    return all_links
  end
end