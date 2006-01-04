#require 'test/unit'
require 'DebugLog'

class Monosaccharide
    include DebugLog
    
    attr_reader :name
    def initialize(name)
        info "Doing the initialisation for #{name}"
        @name = name
        @children = {}
        initialize_from_data()
    end
    
    public
    
    def add_child(mono,linkage)
        if mono.class == String
            mono = Monosaccharide.new(mono)
        end
        @children[linkage] = mono
        return mono
    end
        
    def has_child(linkage)
    	testing_linkage = parse_linkage(linkage)
		test_link = testing_linkage[2]
    	@children.each { |k,v|
    		curr_linkage = parse_linkage(k)
    		if ( test_link == curr_linkage[2] )
    			return true
    		end
    	}
    	return false
    end
    
    def children
        newarray = @children.sort { |a,b|
        	linkagea = parse_linkage(a[0])[2]
        	linkageb = parse_linkage(b[0])[2]
            linkagea<=>linkageb
        }
        return newarray
    end

    def composition
    	descendants = [self]
    	kids = children.collect { |child| child[1] }
    	kids.each { |child|
    		descendants += child.composition
    	}
    	return descendants
    end

        
    def to_s
        stringified = "#{@name}["
        @children.each {|k,v| stringified +="#{k} -> #{v}"}
        stringified += "]\n" 
    end
    
    private
    
    def initialize_from_data
        info "Initialising "+self.name()
    end
    
    def parse_linkage(linkage_string)
    	linkage_string =~ /([abu])([\d\?u])-([\d\?u])/
    	return [ $1,$2,$3 ]
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