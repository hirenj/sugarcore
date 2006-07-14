require 'DebugLog'
require 'Linkage'
require 'SugarException'

require 'rexml/document'
include REXML

# Base Monosaccharide class for representing Monosaccharide units
# Author:: hirenj
class Monosaccharide
    include DebugLog

	LINKAGE_ANOMER = 'linkage_anomer'
	LINKAGE_FIRST_POS = 'linkage_first_pos'
	LINKAGE_SECOND_POS = 'linkage_second_pos'


  # Load the definitions for a particular Monosaccharide dataset
  # This method must be called before any monosaccharides can be
  # instantiated
  def Monosaccharide.Load_Definitions(datafile="data/dictionary.xml")
    @@MONO_DATA_FILENAME = datafile
  	@@MONO_DATA = XPath.match(Document.new( File.new(datafile) ), "/glycanDict")
  end

  # Instantiate a new Monosaccharide using a particular subclass, and having
  # the identifier as specified
  #
  # For example:<br/>
  # <tt>Monosaccharide.factory( NamespacedMonosaccharide, 'Gal' )</tt>
  # or
  # <tt>Monosaccharide.factory( NamespacedMonosaccharide, 'D-Fruf' )</tt>
  def Monosaccharide.factory( classname, identifier )
  	classname.new_mono(identifier)
  end
  
  # The name/identifier for this monosaccharide
  attr_reader :name

  # The namespace that the name of this identifier is found within
  attr		:namespace
    
  def initialize(name)
    debug "Doing the initialisation for #{name}."
    @name = name.strip
    @children = {}
    @ring_positions = {}
    @alternate_name = {}
    initialize_from_data()
  end
    
  private
  
  # New method which is hidden to avoid direct instantiation of the 
  # monosaccharide class
  private_class_method :new
    
  protected
  
  # A wrapper around the new method so that only subclasses can actually
  # directly instantiate a monosaccharide.
  def Monosaccharide.new_mono(*args)
    new(*args)
  end
    
  public
  
  # Add a paired residue to this residue, using the specified
  # linkage. The residue can be either specified as a string, or 
  # as a Monosaccharide object, and the linkage can either be 
  # specified as a string or a Linkage object
  def add_child(mono,linkage)
  	if ! mono.class.ancestors().detect { |aClass| aClass == Monosaccharide }
      mono = Monosaccharide.factory(self.class, mono)
    end
    
  	if ! linkage.class.ancestors().detect { |aClass| aClass == Linkage }
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
  
  # Retrieve an alternate name for this residue, as found in another 
  # namespace
	def alternate_name(namespace)
		if ( ! @alternate_name[namespace] )
			raise MonosaccharideException.new("No name defined in namespace #{namespace} for #{name}")
		end
		return @alternate_name[namespace]
	end

  # Get the set of alternate namespaces defined for this residue
  def alternate_namespaces
      return @alternate_name.keys()
  end

  # The residues which are attached to this residue
  def children
    newarray = @children.sort { |a,b|
    	linkagea = a[0].get_position_for(a[1])
    	linkageb = b[0].get_position_for(b[1])
      linkagea<=>linkageb
    }
    return newarray
  end

  # Consume an attachment position on the ring
	def consume_attachment_position(attachment_position, linkage)
		@ring_positions[attachment_position] = linkage
		# FIXME - NEED TO HAVE LIST OF POSITIONS TO CONSUME
	end

  # Release a residue from the specified attachment position on the ring
  # Will not do anything if the attachment position is not consumed 
	def release_attachment_position(attachment_position)
		@ring_positions.delete(attachment_position)
		# FIXME - NEED TO HAVE LIST OF POSITIONS TO CONSUME
	end

  # Test to see if the attachment position specified has been consumed by
  # another residue
  def attachment_position_consumed?(attachment_position)
    return linkage_at_position(attachment_position) != nil
  end
  
  # The residue at the specified attachment position
	def residue_at_position(attachment_position)
		if ( attachment_position_consumed?(attachment_position) )
			return linkage_at_position(attachment_position).get_paired_residue(self)
		else
			return nil
		end
	end

  # The linkage object associated with any residue attached at the given 
  # attachment position
	def linkage_at_position(attachment_position)
		return @ring_positions[attachment_position]
	end

  # The residue composition of this monosaccharide and all of its attached
  # residue
  def residue_composition
  	descendants = [self]
  	kids = children.collect { |child| child[1] }
  	kids.each { |child|
  		descendants += child.residue_composition
  	}
  	return descendants
  end

  # The Parent residue of this residue - an alias for retrieving the residue found 
  # attached at position 1.
	def parent
		self.residue_at_position(1)
	end

  # String representation of this residue
  def to_s
      stringified = "#{@name}["
      @children.each {|k,v| stringified +="#{k} -> #{v}"}
      stringified += "]\n" 
  end

  # Clean up circular references that this residue may have
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
  	raise MonosaccharideException.new("Trying to initialize base Monosaccharide")
  end
    
  def parse_linkage(linkage_string)
  	if linkage_string =~ /([abu])([\d\?u])-([\d\?u])/
		result = {}
		result[LINKAGE_ANOMER] = $1
		result[LINKAGE_FIRST_POS] = $2.to_i
		result[LINKAGE_SECOND_POS] = $3.to_i
		return result
  	else
  		raise MonosaccharideException.new("Linkage #{linkage_string} is not a valid linkage")
  	end
  end

end

# Residue entity that implements a namespaced monosaccharide
class Namespaced_Monosaccharide < Monosaccharide

	IUPAC_NAMESPACE =  "http://www.iupac.org/condensed"
	GS_NAMESPACE = "http://glycosciences.de"
	
	
	@@DEFAULT_NAMESPACE = IUPAC_NAMESPACE

  # The Default Namespace that new residues will be created in, and in which
  # their names will be validated
	def Namespaced_Monosaccharide.Default_Namespace
		@@DEFAULT_NAMESPACE
	end

  # Set the default namespace to initialise residues from
  # and validate their names in
	def Namespaced_Monosaccharide.Default_Namespace=(ns)
		@@DEFAULT_NAMESPACE = ns
	end

  # List of supported namespaces
  def Namespaced_Monosaccharide.Supported_Namespaces
    return [ GS_NAMESPACE, IUPAC_NAMESPACE ]
  end

  protected
  
	def initialize_from_data
    
    debug "Initialising #{name} in namespace #{self.class.Default_Namespace}."
	
  	mono_data_node = XPath.first(	@@MONO_DATA, 
  									"./unit[@xyz:name='#{@name}']",
  									{ 'xyz' => self.class.Default_Namespace }
  									 )
  #		string(namespace::*[name() =substring-before(@type, ':')]) 
			
  	if ( mono_data_node == nil )
  		raise MonosaccharideException.new("Residue #{self.name} not found in default namespace #{self.class.Default_Namespace} from #{@@MONO_DATA_FILENAME}")
  	end

  	@alternate_name[self.class.Default_Namespace] = self.name()


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