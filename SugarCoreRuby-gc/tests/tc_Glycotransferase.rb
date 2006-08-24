require 'test/unit'
require 'Sugar'
require 'Glycotransferase'

Sugar.log_level(5)

class TC_Glycotransferase < Test::Unit::TestCase
  require 'Sugar/IO/CondensedIupacSugarBuilder'
	require 'Sugar/IO/CondensedIupacSugarWriter'

  LARGE_STRUCTURE = "Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"
  LARGE_STRUCTURE_AFTER_APPLY = "Gal(a1-3)Man(a1-3)[Gal(a1-3)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"

  def build_sugar_from_string(sequence)
    sugar = Sugar.new()
		sugar.extend( CondensedIupacSugarBuilder )
		sugar.extend( CondensedIupacSugarWriter )
    sugar.sequence = sequence
    return sugar
  end

  # Test for making sure that we can load the dictionary
  # file for the Monosaccharide definitions and also 
  # instantiate a Simple sugar
	def test_01_initialisation

		assert_nothing_raised {
			Monosaccharide.Load_Definitions('data/ic-dictionary.xml')
		}
	
	end
	
	def test_recognise_substrate
	  sugar = build_sugar_from_string(LARGE_STRUCTURE)
	  enzyme = Glycotransferase.new()
	  enzyme.substrate_pattern = Monosaccharide.Factory(NamespacedMonosaccharide, 'Man')
	  assert_equal( ['Man','Man','Man'],
	  enzyme.acceptors(sugar).collect { |res|
	    res.name
	  })
	  assert_equal( true, enzyme.accepted_on?(sugar) )
	end
	
	def test_build_theoretical_structures
	  sugar = build_sugar_from_string(LARGE_STRUCTURE)
	  enzyme = Glycotransferase.new()
	  enzyme.substrate_pattern = Monosaccharide.Factory(NamespacedMonosaccharide, 'Man')
	  donor_residue = Monosaccharide.Factory(NamespacedMonosaccharide, 'Gal')
	  donor_linkage = Linkage.Factory(CondensedIupacLinkageBuilder, 'a1-3')
	  donor_linkage.set_first_residue(donor_residue)
	  enzyme.donor = donor_linkage
	  enzyme.apply!(sugar)
	  assert_equal(LARGE_STRUCTURE_AFTER_APPLY, sugar.sequence)
  end
end