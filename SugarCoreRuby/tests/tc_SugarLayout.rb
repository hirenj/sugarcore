require 'test/unit'
require 'Sugar'
require 'Sugar/IO/CondensedIupacSugarBuilder'
require 'Sugar/IO/CondensedIupacSugarWriter'
require 'Render/Renderable'
require 'Render/CondensedLayout'
require 'Render/SvgRenderer'

class Sugar
  include CondensedIupacSugarBuilder
  include CondensedIupacSugarWriter
  include Renderable::Sugar
end

class Monosaccharide
  include Renderable::Residue
end

class Linkage
  include Renderable::Link
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
    sugar.sequence = 'NeuAc(a2-3)Man(b1-6)[Man(b1-3)]Man(a1-3)Man(b1-6)[Man(b1-3)]Man(a1-3)Man(b1-6)[Man(b1-3)]Man(a1-3)GlcNAc(b1-4)GlcNAc'
    sugar
  end
  
  def test_layout
    sugar = a_sugar
    node_num = 0
    renderer = SvgRenderer.new()
    renderer.sugar = sugar
    renderer.initialise_prototypes()

    CondensedLayout.new().layout(sugar)
#    p sugar.box
#    sugar.depth_first_traversal { |res|
#      p sugar.sequence_from_residue(res)
#      p res.position      
#    }
    renderer.render(sugar)
  end
end