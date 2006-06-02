#require 'test/unit'
require 'DebugLog'
require 'Linkage'
require 'SugarException'


require 'rexml/document'
include REXML

class Monosaccharide
    include DebugLog

	LINKAGE_ANOMER = 'linkage_anomer'
	LINKAGE_FIRST_POS = 'linkage_first_pos'
	LINKAGE_SECOND_POS = 'linkage_second_pos'

    def Monosaccharide.Load_Definitions(datafile="data/dictionary.xml")
		@@MONO_DATA = XPath.match(Document.new( File.new(datafile) ), "/glycanDict")
    end
    
    attr_reader :name
    attr		:namespace
    
    def initialize(name)
        debug "Doing the initialisation for #{name}."
        @name = name.strip
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
            mono = Monosaccharide.factory(self.class, mono)
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
		if ( ! @alternate_name[namespace] )
			raise MonosaccharideException.new("No name defined in namespace #{namespace} for #{name}")
		end
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
    
    def finish

        @children.each { |link,node| 
        	link.finish()
        	node.finish()
        }

    	@children = {}

        @ring_positions.each { |pos,node| 
        	node.finish()
        }

    	@ring_positions = {}
    end
    
    private
    
    def initialize_from_data
    	raise "Trying to initialize base Monosaccharide"
    end
    
    def parse_linkage(linkage_string)
    	if linkage_string =~ /([abu])([\d\?u])-([\d\?u])/
			result = {}
			result[LINKAGE_ANOMER] = $1
			result[LINKAGE_FIRST_POS] = $2
			result[LINKAGE_SECOND_POS] = $3
			return result
    	else
    		raise MonosaccharideException.new("Linkage #{linkage_string} is not a valid linkage")
    	end
    end
end

class IUPAC_Monosaccharide < Monosaccharide

	IUPAC_NAMESPACE =  "http://www.iupac.org/condensed"

	def initialize_from_data
        debug "Initialising #{name}."
		mono_data_node = XPath.first(	@@MONO_DATA, 
										"./unit[@ic:name='#{@name}']",
										{ "ic" => IUPAC_NAMESPACE } )

#		string(namespace::*[name() =substring-before(@type, ':')]) 
		
		if ( mono_data_node == nil )
			raise MonosaccharideException.new("Residue #{self.name} not found in default IUPAC namespace")
		end

		@alternate_name[IUPAC_NAMESPACE] = self.name()


		XPath.each(mono_data_node, "./name[@type='alternate']/@value") { |altname|
			namevals = altname.value().split(':',2)
			namespace = namevals[0]
			alternate_name = namevals[1]
			@alternate_name[altname.namespace(namespace)] = alternate_name
			debug "Adding #{alternate_name} in namespace #{namespace} for #{name}."
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