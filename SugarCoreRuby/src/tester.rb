#!/usr/bin/ruby

$:.push('./lib')

require 'logger'
require 'Sugar'
require 'Sugar/IO/CondensedIupacSugarBuilder'
require 'Sugar/IO/CondensedIupacSugarWriter'

Sugar.log_level(Logger::ERROR)

inseq = 'Man(b1-3)[Man(b1-3)[Man(b1-5)][Man(b1-4)]Man(b1-4)]GlcNAc'
sugar = Sugar.new()
sugar.extend( CondensedIupacSugarBuilder )
sugar.extend( CondensedIupacSugarWriter )
sugar.sequence = inseq
inseq2 = 'Man(b1-4)GlcNAc'
sugar2 = Sugar.new()
sugar2.extend( CondensedIupacSugarBuilder )
sugar.extend( CondensedIupacSugarWriter )
sugar2.sequence = inseq2
puts inseq
puts sugar.sequence
sugar.paths().each { |path|
	path.each { |res|
		puts res.name
	}
}
puts sugar.subtract(sugar2)