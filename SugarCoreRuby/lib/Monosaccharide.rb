#require 'test/unit'
require 'DebugLog'
require 'Linkage'

require 'rexml/document'
include REXML

class Monosaccharide
    include DebugLog

	LINKAGE_ANOMER = 'linkage_anomer'
	LINKAGE_FIRST_POS = 'linkage_first_pos'
	LINKAGE_SECOND_POS = 'linkage_second_pos'

	MONO_DATA = XPath.match(Document.new( File.new("data/dictionary.xml") ), "/glycanDict")
    
    attr_reader :name
    
    def initialize(name)
        info "Doing the initialisation for #{name}"
        @name = name
        @children = {}
        @ring_positions = {}
        @alternate_name = {}
        initialize_from_data()
    end
    
    def Monosaccharide.factory( classname, identifier )
    	classname.new(identifier)
    end
    
    public
    
    def add_child(mono,linkage)
        if mono.class == String
        	# FIXME - SHOULD BE USING A FACTORY
            mono = Monosaccharide.new(mono)
        end
        
        # FIXME - SHOULD CHECK INHERITANCE HERE
        
		if linkage.class != Linkage
			linkage_info = parse_linkage(linkage)
			# FIXME - SHOULD BE USING A FACTORY
			linkage = GlycosidicLinkage.new(mono,
											linkage_info[LINKAGE_FIRST_POS],
											self,
											linkage_info[LINKAGE_SECOND_POS],
											linkage_info[LINKAGE_ANOMER])
		end
        @children[linkage] = mono
        return mono
    end

	def alternate_name(namespace)
		return @alternate_name[namespace]
	end

    def children
        newarray = @children.sort { |a,b|
        	linkagea = a[0].get_position_for(a[1])
        	linkageb = b[0].get_position_for(b[1])
            linkagea<=>linkageb
        }
        return newarray
    end

	def consume_attachment_position(attachment_position, linkage)
		@ring_positions[attachment_position] = linkage
		# FIXME - NEED TO HAVE LIST OF POSITIONS TO CONSUME
	end

	def release_attachment_position(attachment_position)
		@ring_positions.delete(attachment_position)
		# FIXME - NEED TO HAVE LIST OF POSITIONS TO CONSUME
	end

    def residue_composition
    	descendants = [self]
    	kids = children.collect { |child| child[1] }
    	kids.each { |child|
    		descendants += child.residue_composition
    	}
    	return descendants
    end

	def get_residue_at_position(attachment_position)
		if ( get_linkage_at_position(attachment_position) )
			return get_linkage_at_position(attachment_position).get_paired_residue(self)
		else
			return
		end
	end

	def get_linkage_at_position(attachment_position)
		return @ring_positions[attachment_position]
	end

	def parent
		self.get_residue_at_position('1')
	end

	def get_path_to_root
		if ( ! self.parent )
			return [ self ]
		end
		return [ self , self.parent.get_path_to_root ].flatten
	end

	def get_attachment_point_path_to_root
		if ( ! parent )
			return []
		end
		linkage = get_linkage_at_position('1');
		return [ linkage.get_position_for(linkage.get_paired_residue(self)),
				 self.parent.get_attachment_point_path_to_root() ].flatten;
	end
     
    def to_s
        stringified = "#{@name}["
        @children.each {|k,v| stringified +="#{k} -> #{v}"}
        stringified += "]\n" 
    end
    
    private
    
    def initialize_from_data
    end
    
    def parse_linkage(linkage_string)
    	linkage_string =~ /([abu])([\d\?u])-([\d\?u])/
    	result = {}
    	result[LINKAGE_ANOMER] = $1
    	result[LINKAGE_FIRST_POS] = $2
    	result[LINKAGE_SECOND_POS] = $3
    	return result
    end
end

class IUPAC_Monosaccharide < Monosaccharide

	IUPAC_NAMESPACE =  "http://www.iupac.org/condensed"

	def initialise_from_data
        info "Initialising "+self.name()

		mono_data_node = XPath.first(	MONO_DATA, 
										"./unit[@ic:name='#{@name}']",
										{ "ic" => IUPAC_NAMESPACE } )

#		string(namespace::*[name() =substring-before(@type, ':')]) 

		XPath.each(mono_data_node, "./name[@type='alternate']/@value") { |altname|
			namevals = altname.value().split(':',2)
			namespace = namevals[0]
			alternate_name = namevals[1]
			@alternate_name[altname.namespace(namespace)] = alternate_name
		}

        # FIXME - ADD ATTACHMENT POSITION INFORMATION	
	end
end

#class TC_MonosaccharideTest < Test::Unit::TestCase
#
#  def test_initialisation
#    assert_nothing_raised { Monosaccharide.new( 'Gal' ) }
#    assert_raises( Password::WeakPassword ) { pw.check }
#  
#  end
#
#end