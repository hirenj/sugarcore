require 'test/unit'
require 'Sugar'
require 'MultiSugar'

NamespacedMonosaccharide.Default_Namespace = :ic

class TC_Sugar < Test::Unit::TestCase
	require 'Sugar/IO/CondensedIupac'
	require 'Sugar/IO/GlycoCT'

  IUPAC_CORE_N_LINKED_FUC = "Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"
  IUPAC_DISACCHARIDE = "Man(a1-3)GalNAc"
  INVALID_SEQUENCE = "aNyTHING124!!?$$"
  IUPAC_SINGLE_RESIDUE = "Man"
  LARGE_STRUCTURE = "Man(a1-3)[Man(a1-6)]Man(b1-4)GlcNAc(b1-4)[Fuc(a1-6)]GlcNAc"
  SMALL_STRUCTURE = "GlcNAc(b1-4)GlcNAc"
  SMALL_STRUCTURE_2 = "GlcNAc(b1-3)GlcNAc"
  SMALL_STRUCTURE_3 = "GalNAc(b1-3)GalNAc"
  SMALL_STRUCTURE_4 = "GlcNAc(a1-4)GlcNAc"
  UNKNOWN_STRUCTURE = "Gal(b1-u)[Fuc(a1-u)]GalNAc"
  UNKNOWN_STRUCTURE_2 = "Gal(b1-3)[Gal(b1-u)][Fuc(a1-u)]GlcNAc"
  MASSIVE_UNION_STRUCTURES = [
  "NeuGc(a2-8)NeuAc(a2-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)Glc",
  "Fuc(a1-3)Fuc(a1-3)Fuc(a1-2)Gal(b1-3)[Fuc(a1-4)][GalNAc(a1-3)]GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)Glc",
  "Gal(b1-4)GlcNAc(b1-6)Gal(b1-4)Glc",
  "Gal(a1-3)[GalNAc(a1-3)]NeuAc(a2-6)Fuc(a1-2)[Gal(a1-3)]Gal(b1-4)GlcNAc(b1-6)NeuAc(a2-u)[NeuAc(a2-6)][NeuGc(a2-3)][GlcA(b1-3)]NeuAc(a2-3)NeuAc(a2-3)[NeuAc(a2-6)][Fuc(a1-2)Gal(b1-4)GlcNAc(b1-6)][Gal(b1-4)GlcNAc(b1-3)]Gal(a1-4)Fuc(a1-2)[Gal(a1-3)][GalNAc(a1-3)]Gal(b1-4)GlcNAc(b1-3)[NeuAc(a2-3)]Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)Glc",
  "Fuc(a1-3)Fuc(a1-3)Fuc(a1-3)Fuc(a1-3)Fuc(a1-3)GlcNAc(b1-3)Gal(b1-4)Glc",
  "NeuAc(a2-8)NeuAc(a2-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)Glc",
  "Fuc(a1-3)[Gal(b1-4)]GlcNAc(b1-3)NeuAc(a2-3)Gal(b1-4)GlcNAc(b1-3)[NeuAc(a2-3)]Fuc(a1-2)[NeuAc(a2-6)][Fuc(a1-3)[Fuc(a1-2)[NeuAc(a2-3)][Gal(a1-3)]Gal(b1-4)]GlcNAc(b1-3)][GalNAc(a1-3)][NeuAc(a2-3)]Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)Glc"
  ]

MASSIVE_UNION_STRUCTURES_2 = 
[  
"GalNAc(a1-3)Gal",
"Fuc(a1-2)Gal",
"Fuc(a1-2)Gal",
"GalNAc(a1-3)Gal",
"Fuc(a1-3)[Gal(b1-4)]GlcNAc(b1-3)Gal",
"GlcNAc(b1-3)Gal",
"Fuc(a1-3)[NeuAc(a2-3)Gal(b1-4)]GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal",
"Fuc(a1-3)[Fuc(a1-2)Gal(b1-4)]GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-4)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-4)GlcNAc(b1-6)Gal",
"NeuAc(a2-6)Gal(b1-4)GlcNAc(b1-3)Gal",
"NeuAc(a2-3)Gal(b1-4)GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-3)Gal",
"Gal(b1-3)[Fuc(a1-4)]GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal(b1-4)GlcNAc(b1-3)Gal",
"NeuAc(a2-3)Gal(b1-3)[Fuc(a1-4)]GlcNAc(b1-3)Gal(b1-3)GlcNAc(b1-3)Gal",
"Fuc(a1-3)[Fuc(a1-2)Gal(b1-4)]GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-4)GlcNAc(b1-6)Gal",
"Fuc(a1-2)Gal(b1-3)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-4)GlcNAc(b1-6)Gal",
"NeuAc(a2-3)Gal(b1-3)[Fuc(a1-4)]GlcNAc(b1-3)Gal",
"Fuc(a1-3)[Fuc(a1-2)Gal(b1-4)]GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-6)Gal",
"Fuc(a1-3)[Fuc(a1-3)[Gal(b1-4)]GlcNAc(b1-3)Gal(b1-4)]GlcNAc(b1-3)Gal",
"NeuAc(a2-3)Gal(b1-3)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-4)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal",
"Fuc(a1-2)Gal",
"Gal(a1-3)Gal",
"NeuAc(a2-6)Gal",
"Gal(b1-3)GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-6)Gal",
"Gal(b1-4)GlcNAc(b1-3)[Gal(b1-4)GlcNAc(b1-6)]Gal(b1-4)GlcNAc(b1-3)Gal",
"Gal(b1-4)GlcNAc(b1-3)[GlcNAc(b1-6)]Gal(b1-4)GlcNAc(b1-3)Gal",
"NeuAc(a2-u)Gal",
"Gal(b1-4)GlcNAc(b1-6)Gal",
"Fuc(a1-2)Gal(b1-u)GlcNAc(b1-u)Gal",
"Fuc(a1-2)Gal(b1-u)GlcNAc(b1-u)Gal",
"Fuc(a1-2)Gal(b1-u)GlcNAc(b1-u)[Fuc(a1-2)Gal(b1-u)GlcNAc(b1-u)]Gal(b1-u)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-u)GlcNAc(b1-3)Gal",
"Fuc(a1-2)Gal(b1-u)[Fuc(a1-u)]GlcNAc(b1-u)[Fuc(a1-2)Gal(b1-u)GlcNAc(b1-u)]Gal(b1-u)GlcNAc(b1-3)Gal"
]
  
  
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
\\\\\\
LIN
1:1o(4+1)5d;
2:1o(6+1)4d;
3:5o(4+1)6d;
4:6o(3+1)2d;
5:6o(6+1)3d;
6:1d(2+1)8n;
7:4d(6+1)7n;
8:5d(2+1)8n;
\\\\\\\\\\
__FOO__

	DebugLog.log_level(5)

  def build_sugar_from_components
    sugar = Sugar.new()
		sugar.extend(  Sugar::IO::CondensedIupac::Builder )
		sugar.extend(  Sugar::IO::CondensedIupac::Writer )
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

  def build_multi_sugar_from_string(sequence)
    sugar = Sugar.new()
		sugar.extend( Sugar::IO::CondensedIupac::Builder )
		sugar.extend( Sugar::IO::CondensedIupac::Writer )
		sugar.extend( Sugar::MultiSugar )
    sugar.sequence = sequence
    return sugar
  end

  def build_sugar_from_string(sequence)
    sugar = Sugar.new()
		sugar.extend(  Sugar::IO::CondensedIupac::Builder )
		sugar.extend(  Sugar::IO::CondensedIupac::Writer )
    sugar.sequence = sequence
    return sugar
  end

  # Test for making sure that we can load the dictionary
  # file for the Monosaccharide definitions and also 
  # instantiate a Simple sugar
	def setup
		Monosaccharide.Load_Definitions('data/dictionary.xml')	
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
			sugar.extend(  Sugar::IO::CondensedIupac::Builder )
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
		sugar.extend(  Sugar::IO::CondensedIupac::Builder )
		sugar.extend(  Sugar::IO::CondensedIupac::Writer )
    sugar.sequence = LARGE_STRUCTURE
    
    assert_equal( LARGE_STRUCTURE, sugar.sequence)
    
    assert_nothing_raised {
      sugar = Sugar.new()
			sugar.extend(  Sugar::IO::CondensedIupac::Builder )
			sugar.extend(  Sugar::IO::CondensedIupac::Writer )
      sugar.sequence = IUPAC_DISACCHARIDE
      sugar.target_namespace = NamespacedMonosaccharide::NAMESPACES[:dkfz]
    }
    sugar = Sugar.new()
    sugar.extend( Sugar::IO::CondensedIupac::Builder )
    sugar.extend( Sugar::IO::GlycoCT::Writer )
    sugar.sequence = LARGE_STRUCTURE
    sugar.target_namespace = :ecdb
    assert_equal( LARGE_STRUCTURE_AS_CT, sugar.sequence)

  end 


  # Tests that sequences are parsed properly for a particular namespace
	def test_iupac_sequences
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  Sugar::IO::CondensedIupac::Builder )
			sugar.sequence = IUPAC_DISACCHARIDE
		}
		assert_raises( SugarException ) {
			sugar = Sugar.new()
			sugar.extend(  Sugar::IO::CondensedIupac::Builder )			
			sugar.sequence = INVALID_SEQUENCE		
		}
	end

	def test_composition
		assert_nothing_raised {
			sugar = Sugar.new()
			sugar.extend(  Sugar::IO::CondensedIupac::Builder )
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
  
  def test_unknown_linkages
    sugar = build_sugar_from_string( UNKNOWN_STRUCTURE )
    assert_equal( sugar.sequence, "Fuc(a1-u)[Gal(b1-u)]GalNAc" )
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
  
  def test_sugar_intersection_with_comparator
		sugar = build_sugar_from_string( SMALL_STRUCTURE )
    sugar2 = build_sugar_from_string( SMALL_STRUCTURE_4 )    
    assert_equal( ['GlcNAc'], sugar.intersect(sugar2).collect { |residue| 
      residue.name
    })
    assert_equal( ['GlcNAc','GlcNAc'], sugar.intersect(sugar2) { |r1,r2| 
      r1.name(:ic) == r2.name(:ic)
    }.collect { |residue| 
      residue.name
    })    
  end
  
  def test_sugar_union
    sugar = build_multi_sugar_from_string("Gal(a1-3)GlcNAc")
    sugar2 = build_sugar_from_string("GlcNAc(b1-4)Fuc(b1-6)GlcNAc")
    sugar3 = build_sugar_from_string("Gal(b1-3)GlcNAc")
    sugar4 = build_sugar_from_string("GlcNAc(b1-4)Gal(b1-3)GlcNAc")   
    sugar.union!(sugar2).union!(sugar3).union!(sugar4)
    assert_equal('Gal(a1-3)[GlcNAc(b1-4)Fuc(b1-6)][GlcNAc(b1-4)Gal(b1-3)]GlcNAc', sugar.sequence)
  end

  def test_sugar_unique_maker
    sugar = build_multi_sugar_from_string( 'Gal(b1-3)GlcNAc(a1-u)[Fuc(a1-3)GlcNAc(a1-u)]GlcNAc')
    puts sugar.get_unique_sugar.extend(  Sugar::IO::CondensedIupac::Writer ).sequence
  end

  def test_sugar_union_with_unknowns
    sugars = MASSIVE_UNION_STRUCTURES_2.collect { |sug| build_multi_sugar_from_string( sug ) }
    end_sugar = sugars.shift
#		end_sugar.extend( Sugar::MultiSugar )
    sugars.each { |sug|
      end_sugar.union!(sug.get_unique_sugar)
    }
    puts end_sugar.sequence
  end


  def test_multi_sugar_union
    sugar = build_multi_sugar_from_string("GlcNAc(b1-4)GlcNAc")
    sugar2 = build_multi_sugar_from_string("Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar3 = build_multi_sugar_from_string("GlcNAc(b1-4)Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar4 = build_multi_sugar_from_string("GlcNAc(b1-4)Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar5 = build_multi_sugar_from_string("GlcNAc(b1-4)Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar6 = build_multi_sugar_from_string("GlcNAc(b1-4)Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar7 = build_multi_sugar_from_string("GlcNAc(b1-4)Man(a1-6)[Man(a1-3)]Man(b1-4)GlcNAc(b1-4)GlcNAc")
    sugar.union!(sugar2).union!(sugar3).union!(sugar4).union!(sugar5).union!(sugar6).union!(sugar7) { |res,test_res|
      if res.equals?(test_res)
        true
      else
        false
      end
    }
    assert_equal('Man(a1-3)[GlcNAc(b1-4)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc', sugar.sequence)
  end

  def test_multi_sugar_union_again
    sug_a = build_multi_sugar_from_string('GlcNAc(b1-4)Man(a1-3)[GlcNAc(b1-4)Man(a1-6)]Man(b1-4)GlcNAc(b1-4)GlcNAc')
    sug_b = build_multi_sugar_from_string('NeuAc(a2-3)[Fuc(a1-3)][Gal(a1-3)]GlcNAc(b1-4)Man(a1-3)Man(b1-4)GlcNAc(b1-4)GlcNAc')
    puts sug_a.union!(sug_b) {|r,r2|
      if r.equals?(r2)
        true
      else
        false
      end
    }.sequence
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
  
  def test_sugar_path_to_root
    sugar = build_sugar_from_string( LARGE_STRUCTURE )
		assert_equal(
		[ 'Man(a1-3)Man(b1-4)GlcNAc(b1-4)GlcNAc',
		  'Man(a1-6)Man(b1-4)GlcNAc(b1-4)GlcNAc',
		  'Fuc(a1-6)GlcNAc'
		 ],		
		sugar.leaves.collect { |leaf|
		  new_sug = sugar.get_sugar_to_root(leaf).extend(  Sugar::IO::CondensedIupac::Writer )
		  seq = new_sug.sequence
		  new_sug.finish
		  seq
		})
  end
  
  def test_build_sugar_from_path
    sugars = MASSIVE_UNION_STRUCTURES.collect { |sug| build_multi_sugar_from_string( sug ) }
    end_sugar = sugars.shift
    sugars.each { |sug|
      end_sugar.union!(sug)
    }
#    puts end_sugar.sequence
  end
  
  def test_multisugar_intersect
    sugar = build_sugar_from_string("Gal(a1-3)GlcNAc")
    sugar2 = build_sugar_from_string("GlcNAc(b1-4)Fuc(b1-6)GlcNAc")
    sugar3 = build_sugar_from_string("Gal(b1-3)GlcNAc")
    sugar4 = build_sugar_from_string("Gal(a1-3)GlcNAc")
    sugar.extend(Sugar::MultiSugar).union!(sugar2).union!(sugar3)
    assert_equal(['Gal','GlcNAc'],sugar.intersect(sugar4).collect { |r| r.name(:ic) }.sort)
  end
  
  def test_sugar_clone
    sugar = build_sugar_from_string( LARGE_STRUCTURE )
    sugar2 = sugar.dup
		sugar2.extend(  Sugar::IO::CondensedIupac::Writer )    
    assert_equal(LARGE_STRUCTURE, sugar2.sequence)
  end
end

