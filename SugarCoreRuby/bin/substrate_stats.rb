#!/usr/bin/env ruby
#
#  Created by Hiren Joshi on 2007-10-16.
#  Copyright (c) 2007. All rights reserved.

$:.push('lib')

require 'Sugar'
require 'Sugar/IO/CondensedIupac'
require 'Sugar/IO/GlycoCT'
require 'Sugar/IO/Glyde'
require 'SugarException'

Monosaccharide.Load_Definitions("data/dictionary.xml")
NamespacedMonosaccharide.Default_Namespace = NamespacedMonosaccharide::NAMESPACES[:glyde]


module Sugar::IO::GlycoCT::Builder
  
  ALIASED_NAMES = {
    'dgal-hex-x:x'            => 'dgal-hex-1:5',
    'dgal-hex-x:x|2n-acetyl'  => 'dgal-hex-1:5|2n-acetyl',
    'dglc-hex-x:x'            => 'dglc-hex-1:5',
    'dglc-hex-x:x|6:a'        => 'dglc-hex-1:5|6:a',
    'dglc-hex-x:x|2n-acetyl'  => 'dglc-hex-1:5|2n-acetyl',
    'dman-hex-x:x'            => 'dman-hex-1:5',
    'dgro-dgal-non-x:x|1:a|2:keto|3:d|5n-acetyl'  => 'dgro-dgal-non-2:6|1:a|2:keto|3:d|5n-acetyl'
  }
  
  alias_method :builder_factory, :monosaccharide_factory
  def monosaccharide_factory(name)
    return builder_factory(ALIASED_NAMES[name] || name)
  end
end

DebugLog.log_level(5)
count = 0

buckets = {}
parent_buckets = {}
parent_buckets.default = 0
buckets.default = 0


File.open("data/human_glycosciences.dump","r") do |file|
  while (line = file.gets)
    id,sequence = line.split(/\s+/)
    sequence.gsub!(/\\n/,"\n")
    next if sequence.match(/REPEAT/)
    sug = Sugar.new()
    sug.extend(Sugar::IO::GlycoCT::Builder)
    sug.extend(Sugar::IO::CondensedIupac::Writer)
    sug.target_namespace = :ic
    begin
      sug.sequence = sequence
      residues = sug.composition_of_residue('dgal-hex-x:x')
      residues.each { |res|
        child_res = res.residue_at_position(4)
        if child_res && child_res.anomer == 'b' && child_res.name(:ic) == "GalNAc"
          siblings = res.children.reject {|r| r[:residue] == child_res }
          siblings.each { |sibling|
            sib = sibling[:residue]
            link = sibling[:link]
            name = "#{sib.name(:ic)}#{sib.anomer}#{link.get_position_for(sib)}#{link.get_position_for(res)}"
            buckets[name] += 1
            if res.parent
              parent_name = res.parent.name(:ic).gsub!(/-ol/,'')
              parent_buckets[res.parent.name(:ic)] += 1
            end
          }
          count += 1
        end
      }
    rescue MonosaccharideException => err
        p err
    ensure
        sug.finish
    end
  end
end
p count
buckets.keys.each { |name|
  p "Residue #{name} has #{buckets[name]}"
}
parent_buckets.keys.each { |name|
  p "Parent residue #{name} has #{parent_buckets[name]}"
}