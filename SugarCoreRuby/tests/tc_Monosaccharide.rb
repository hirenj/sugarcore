require 'test/unit'
require 'Monosaccharide'

class TC_Monosaccharide < Test::Unit::TestCase
	require 'Sugar/IO/CondensedIupacSugarBuilder'
	require 'Sugar/IO/CondensedIupacSugarWriter'

	DebugLog.log_level(5)

	def test_01_initialisation

		assert_nothing_raised {
			Monosaccharide.Load_Definitions('data/ic-dictionary.xml')
		}

    assert_raise(NoMethodError) {  
      Monosaccharide.new('Foobar')
    }
	 
	end

	def test_simple_namespace
		assert_nothing_raised {
			mono = Monosaccharide.factory( Namespaced_Monosaccharide, 'Gal')
		}
		
		# We should not be able to create this Monosaccharide as it is
		# not in the target namespace
		
		assert_raise( MonosaccharideException ) {
			Monosaccharide.factory( Namespaced_Monosaccharide, 'SomeNamespace')		  
		}
	end

  def test_namespace_switching
		
		# We should be able to use the DKFZ namespace here
		
		assert_nothing_raised {
		  Namespaced_Monosaccharide.Default_Namespace=Namespaced_Monosaccharide::GS_NAMESPACE
		  Namespaced_Monosaccharide.Load_Definitions('data/dkfz-dictionary.xml')
			mono = Monosaccharide.factory( Namespaced_Monosaccharide, 'D-Araf')
		}
		
		# We shouldn't be able to use IUPAC here
		
		assert_raise( MonosaccharideException ) {
		  Monosaccharide.factory( Namespaced_Monosaccharide, 'Gal')
		}
		
		# We should reset the namespace here
	  Namespaced_Monosaccharide.Default_Namespace=Namespaced_Monosaccharide::IUPAC_NAMESPACE
	  test_01_initialisation()
  end

  def test_alternate_namespaces
    mono = Monosaccharide.factory( Namespaced_Monosaccharide, 'Gal')
    assert_equal(2, mono.alternate_namespaces.length)
    assert_equal(mono.alternate_namespaces.sort,
          ['http://glycosciences.de','http://www.iupac.org/condensed'])
  end

  def test_attachment_position_consumption
    mono1 = Monosaccharide.factory( Namespaced_Monosaccharide, 'Gal')
    mono2 = Monosaccharide.factory( Namespaced_Monosaccharide, 'Glc')
    mono3 = Monosaccharide.factory( Namespaced_Monosaccharide, 'Man')
    mono1.add_child(mono2, "a1-3")
    mono1.add_child(mono3, "a1-4")
    assert_equal(2,mono1.children.length)
    assert(mono1.attachment_position_consumed?(3) &&
           mono1.attachment_position_consumed?(4) ,
           "Attachment positions not consumed by linkages")
    assert( mono1.attachment_position_consumed?(2) != true,
            "Attachment position mistakenly consumed")
    assert( mono1.residue_at_position(3) == mono2 &&
            mono1.residue_at_position(4) == mono3,
            "Attachment positions correctly mapped to residues")
    assert_equal([3,4], mono1.consumed_positions.sort)
    mono2.finish()
    mono3.finish()
    mono1.finish()
  end



end


