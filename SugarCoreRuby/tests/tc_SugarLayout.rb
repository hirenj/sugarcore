require 'test/unit'
require 'Sugar'
require 'Sugar/IO/CondensedIupacSugarBuilder'
require 'Sugar/IO/CondensedIupacSugarWriter'
require 'Render/Renderable'
require 'Render/CondensedLayout'

class Sugar
  include CondensedIupacSugarBuilder
  include CondensedIupacSugarWriter
  include Renderable
end

class Monosaccharide
  include Renderable
end

class Linkage
  include Renderable
end

DebugLog.log_level(5)

class TC_SugarLayout < Test::Unit::TestCase

  # Test for making sure that we can load the dictionary
  # file for the Monosaccharide definitions and also 
  # instantiate a Simple sugar
	def test_01_initialisation

		assert_nothing_raised {
			Monosaccharide.Load_Definitions('data/ic-dictionary.xml')
		}
	
		assert_nothing_raised {
			sugar = Sugar.new()
		}
 
	end

  def a_sugar
    sugar = Sugar.new()
    sugar.sequence = 'Gal(b1-3)[Man(b1-4)][Fuc(b1-5)][Glc(b1-6)]Gal(b1-3)[Man(b1-4)][Fuc(b1-5)][Glc(b1-6)]GlcNAc'
    sugar
  end
  
  def test_layout
    sugar = a_sugar
    node_num = 0
    CondensedLayout.layout(sugar)
#    p sugar.box
#    sugar.depth_first_traversal { |res|
#      p sugar.sequence_from_residue(res)
#      p res.position      
#    }
  end
end