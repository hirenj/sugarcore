module Sugar::IO::GlycoCT::Builder

  def self.append_features(base)
    super(base)
    class << base
      def ResidueClass
        NamespacedMonosaccharide
      end
      def LinkageClass
        Linkage
      end      
    end
  end
  
  def residueClass
    NamespacedMonosaccharide
  end
  
  def linkageClass
    Linkage    
  end

  def monosaccharide_factory(prototype)
    return Monosaccharide.Factory(residueClass,prototype)
  end
  
  def linkage_factory(prototype)
    return Linkage.Factory(linkageClass, prototype)
  end


  class Residue
    attr_accessor :res_id, :name, :res_type, :anomer
    def self.factory(string)
      res = new()
      res.res_id, res.res_type, res.anomer, res.name = [string.scan(/(\d+)([bs]):(?:([abu])-)?(.*)/)].flatten
      if ( ! res.name )
        res.name = res.anomer
      end
      res.res_type = res.res_type.to_sym
      res
    end
  end

  class ParseLinkage
    attr_accessor :link_id, :from, :to, :from_position, :to_position
    def self.factory(string)
      link = new()
      link.link_id, link.from, link.from_position, link.to_position, link.to = [ string.scan(/(\d+):(\d+)\w?\(([\du]+)-([\du]+)\)(\d)+/)].flatten
      link
    end
  end


  def parse_sequence(sequence)
    glycoct_residues = Hash.new()
    glycoct_linkages = Hash.new()

    residues, linkages = [sequence.scan(/RES\n(.*)LIN\n(.*)/m)].flatten.collect { |block| block.split(";\n") }
    residues.collect { |res_string| Sugar::IO::GlycoCT::Builder::Residue.factory(res_string) }.each { |res| glycoct_residues[res.res_id] = res }
    linkages.collect { |link_string| Sugar::IO::GlycoCT::Builder::ParseLinkage.factory(link_string) }.each { |link| glycoct_linkages[link.link_id] = link }

    residues = glycoct_residues
    linkages = glycoct_linkages

    collapse_substituents(linkages,residues)
    
    root = nil
    linkages.keys.select { |id| linkages[id].from != nil }.sort_by { |id| residues[linkages[id].from].res_id }.each { |id|
      link = linkages[id]
      residue = residues[link.from]
      unless residue.is_a?(Monosaccharide)
        residue = monosaccharide_factory(residues[link.from].name)
        residue.anomer = residues[link.from].anomer
      end
      residues[link.from] = residue

      to_residue = residues[link.to]
      unless to_residue.is_a?(Monosaccharide)
        to_residue = monosaccharide_factory(residues[link.to].name)
        to_residue.anomer = residues[link.to].anomer
      end
      residues[link.to] = to_residue

      if (id.to_i == 1)
        root = residue
      end
      linkage = linkage_factory({:from => link.from_position, :to => link.to_position})
      residue.add_child(to_residue,linkage)
    }
    return root
  end
  
  def collapse_substituents(linkages,residues)
    linkages.each { |link_id,link|
      if (residues[link.to].res_type == :s)
        residues[link.from].name = "#{residues[link.from].name}|#{link.from_position}#{residues[link.to].name}"
        link.from = nil
        link.to = nil
      end    
    }
  end
end