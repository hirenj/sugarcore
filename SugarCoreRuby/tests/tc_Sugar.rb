require 'test/unit'
require 'Sugar'

class TC_Sugar < Test::Unit::TestCase
	require 'Sugar/IO/CondensedIupacSugarBuilder'
	require 'Sugar/IO/CondensedIupacSugarWriter'
	require 'Sugar/IO/GlycoCTWriter'

  IUPAC_CORE_N_LINKED_FUC = "Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"
  IUPAC_DISACCHARIDE = "Man(a1-3)GalNAc"
  INVALID_SEQUENCE = "aNyTHING124!!?$$"
  IUPAC_SINGLE_RESIDUE = "Man"
  LARGE_STRUCTURE = "Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"
  SMALL_STRUCTURE = "GlcNAc(b1-4)GlcNAc"
  SMALL_STRUCTURE_2 = "GlcNAc(b1-3)GlcNAc"
  SMALL_STRUCTURE_3 = "GalNAc(b1-3)GalNAc"
  LARGE_STRUCTURE_AS_CT = <<__FOO__
RES
1b:u-dglcp;
2b:a-dmanp;
3b:a-dmanp;
4b:a-lgalp;
5b:b-dglcp;
6b:b-dmanp;
7s:d;
8s:nac;
LIN
1:1(4-1)5;
2:1(6-1)4;
3:5(4-1)6;
4:6(3-1)2;
5:6(6-1)3;
6:1o(2-1)8;
7:4o(6-1)7;
8:5o(2-1)8;
__FOO__

	DebugLog.log_level(5)

  def build_sugar_from_components
    sugar = Sugar.new()
		sugar.extend(  CondensedIupacSugarBuilder )
		sugar.extend(  CondensedIupacSugarWriter )
    monos = [ sugar.monosaccharide_factory( 'GlcNAc' ),
              sugar.monosaccharide_factory( 'Man' ),
              sugar.monosaccharide_factory( 'Man' ),
              sugar.monosaccharide_factory( 'Man' )
            ]
    sugar.sequence = 'GlcNAc'
    root_mono = sugar.residue_composition.shift
    root_mono.add_child(monos[0],sugar.linkage_factory('b1-4'))
    monos[0].add_child(monos[1],sugar.linkage_factory('b1-4'))
    monos[1].add_child(monos[2],sugar.linkage_factory('a1-3'))
    monos[1].add_child(monos[3],sugar.linkage_factory('a1-6'))
    return { "sugar" => sugar , "monos" => [root_mono]+monos }
  end

  def build_sugar_from_string(sequence)
    sugar = Sugar.new()
		sugar.extend(  CondensedIupacSugarBuilder )
		sugar.extend(  CondensedIupacSugarWriter )
    sugar.sequence = sequence
    return sugar
  end

  # Test for making sure that we can load the dictionary
  # file for the Monosaccharide definitions and also 
  # instantiate a Simple sugar
	def test_01_initialisation

		assert_nothing_raised {
			Monosaccharide.Load_Definitions('data/dictionary.xml')
		}
	
		assert_nothing_raised {
			sugar = Sugar.new()
		}
 
	end

  # Tests the extension capability of the Sugar to handle
  # different sequence types
  def test_parsing
    assert_raises( SugarException ) {
      sugar = Sugar.new()
      sugar.sequence = INVALID_SEQUENCE
    }
    assert_nothing_raised {
      sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
      sugar.sequence = IUPAC_DISACCHARIDE
    }
  end 

  # Tests the extension capability of the Sugar to handle
  # different sequence types
  def test_writing
    assert_raises( SugarException ) {
      sugar = Sugar.new()
      sugar.sequence
    }
    
    sugar = Sugar.new()
		sugar.extend(  CondensedIupacSugarBuilder )
		sugar.extend(  CondensedIupacSugarWriter )
    sugar.sequence = LARGE_STRUCTURE
    
    assert_equal( LARGE_STRUCTURE, sugar.sequence)
    
    assert_nothing_raised {
      sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
			sugar.extend(  CondensedIupacSugarWriter )
      sugar.sequence = IUPAC_DISACCHARIDE
      sugar.target_namespace = NamespacedMonosaccharide::GS_NAMESPACE
    }
    sugar = Sugar.new()
    sugar.extend( CondensedIupacSugarBuilder )
    sugar.extend( GlycoCTWriter )
    sugar.sequence = LARGE_STRUCTURE
    assert_equal( LARGE_STRUCTURE_AS_CT, sugar.sequence)

  end 


  # Tests that sequences are parsed properly for a particular namespace
	def test_iupac_sequences
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
			sugar.sequence = IUPAC_DISACCHARIDE
		}
		assert_raises( MonosaccharideException ) {
			sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )			
			sugar.sequence = INVALID_SEQUENCE		
		}
	end

	def test_composition
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  CondensedIupacSugarBuilder )
			sugar.sequence = IUPAC_DISACCHARIDE
			sugar.residue_composition()
			sugar.composition_of_residue(IUPAC_SINGLE_RESIDUE)
		}
	end
	
	def test_subcomponents
	  results = build_sugar_from_components()
	  assert_equal("Man(a1-3)[Man(a1-6)]Man",
	               results['sugar'].sequence_from_residue(
	                  results['monos'][2]
	                )
	              )
	  assert_equal(
	    [],
      results['monos'] - results['sugar'].residue_composition
	  )
  end
  
  def test_paths
	  results = build_sugar_from_components()
    assert_equal(
      [],
      [ [ results['monos'][4], results['monos'][2],results['monos'][1],results['monos'][0]],
        [ results['monos'][3], results['monos'][2],results['monos'][1],results['monos'][0]]
      ] - results['sugar'].paths
    )
  end
  
  def test_leaves
	  results = build_sugar_from_components()
    assert_equal(
      [],
      results['sugar'].leaves - [ results['monos'][3], results['monos'][4] ]
    )
  end
    
  def test_traversals
    sugar = build_sugar_from_string( LARGE_STRUCTURE )
    results = []
    printblock = lambda { |residue|
      results.push(residue.name + "," + residue.paired_residue_position(1).to_s +  ":" + residue.consumed_positions.sort.join(","))
    }
    sugar.breadth_first_traversal &printblock 
    assert_equal(['GlcNAc,:4,6','GlcNAc,4:1,4','Fuc,6:1','Man,4:1,3,6','Man,3:1','Man,6:1'], results)
    results = []
    sugar.depth_first_traversal &printblock
    assert_equal(['GlcNAc,:4,6','GlcNAc,4:1,4','Man,4:1,3,6','Man,3:1','Man,6:1','Fuc,6:1'], results)
    
  end
  
  def test_sugar_comparator
		sugar = build_sugar_from_string( LARGE_STRUCTURE )
    sugar2 = build_sugar_from_string( SMALL_STRUCTURE )
    sugar3 = build_sugar_from_string( SMALL_STRUCTURE_2 )


    residue_comparator = lambda { |residue1, residue2|
      (residue1.name == residue2.name ) &&
      (residue1.paired_residue_position(1) == residue2.paired_residue_position(1)) &&
      ((residue1.parent == nil && residue2.parent == nil) || residue1.parent.name == residue2.parent.name)
    }

    comparison_result = sugar.compare_by_block(sugar, :depth_first_traversal, &residue_comparator)

    assert_equal(true, comparison_result)

    comparison_result = sugar.compare_by_block(sugar2, &residue_comparator) 

    assert_equal(false, comparison_result)

    comparison_result = sugar2.compare_by_block(sugar3, &residue_comparator) 

    assert_equal(false, comparison_result)

  end
  
  def test_sugar_interesction
		sugar = build_sugar_from_string( SMALL_STRUCTURE )
    sugar2 = build_sugar_from_string( LARGE_STRUCTURE )
    sugar3 = build_sugar_from_string( SMALL_STRUCTURE_2 )
    sugar4 = build_sugar_from_string( SMALL_STRUCTURE_3 )


    assert_equal( ['GlcNAc', 'GlcNAc'], sugar.intersect(sugar2).collect { |residue| 
      residue.name
    })
    assert_equal( ['GlcNAc', 'GlcNAc'], sugar.intersect(sugar).collect { |residue| 
      residue.name
    })
    assert_equal( ['GlcNAc'], sugar.intersect(sugar3).collect { |residue| 
      residue.name
    })
    assert_equal( [], sugar.intersect(sugar4).collect { |residue| 
      residue.name
    })

  end
  
  def test_sugar_subtraction
    sugar = build_sugar_from_string( LARGE_STRUCTURE )
		sugar2 = build_sugar_from_string( SMALL_STRUCTURE )
    assert_equal( ['Fuc','Man','Man','Man'], sugar.subtract(sugar2).collect{ |residue|
      residue.name
    }.sort)
    
    sugar = build_sugar_from_string( 'LFuc(a1-2)[GalNAc(a1-3)]Gal(b1-3)GlcNAc(b1-3)Gal')
    sugar2 = build_sugar_from_string( 'LFuc(a1-2)Gal(b1-3)GlcNAc(b1-3)Gal')
    assert_equal( ['GalNAc'], sugar.subtract(sugar2).collect{ |residue|
      residue.name
    })
    
  end
  
  def test_sugar_clone
    sugar = build_sugar_from_string( LARGE_STRUCTURE )
    sugar2 = sugar.dup
		sugar2.extend(  CondensedIupacSugarWriter )    
    assert_equal(LARGE_STRUCTURE, sugar2.sequence)
  end
end

