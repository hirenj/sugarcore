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
    'xgal-hex-1:5'            => 'dgal-hex-1:5',
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
    name.gsub!(/\|\dsulfate/,'')
    return builder_factory(ALIASED_NAMES[name] || name)
  end
end

DebugLog.log_level(5)
count = 0
disac_count = 0

all_sibs = {}
all_parents = {}
disaccharides = Array.new()

results = Hash.new() { |hash,key| hash[key] = { :buckets => Hash.new() { |h,k| all_sibs[k] = 1; h[k] = 0 }, :parent_buckets => Hash.new() { |h,k| all_parents[k] = 1; h[k] = 1 } } }

File.open("data/disaccharides_dump.txt","r") do |file|
  seq = ''
  while (line = file.gets)
    if (line == "---\n")
      sug = Sugar.new()
      sug.extend(Sugar::IO::GlycoCT::Builder)
      sug.extend(Sugar::IO::GlycoCT::Writer)
      sug.target_namespace = :glyde
      sug.sequence = seq
      seq = ''
      donor, substrate = sug.paths[0]
      disaccharides << { :donor => donor.name, :substrate => substrate.name, :anomer => donor.anomer, :posn => donor.paired_residue_position}
      sug.finish
    else
      seq += line
    end
  end
end

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
      puts sug.sequence
      disaccharides.each { |disac|
        residues = sug.composition_of_residue(disac[:substrate])
        residues.each { |res|
          child_res = res.residue_at_position(disac[:posn])
          if child_res && child_res.anomer == disac[:anomer] && child_res.name(:glyde) == disac[:donor]
            siblings = res.children.reject {|r| r[:residue] == child_res }
            if siblings.size == 0
              results[disac][:buckets]["alone"] += 1
            end
            results[disac][:buckets]["total"] += 1
            siblings.each { |sibling|
              sib = sibling[:residue]
              link = sibling[:link]
              name = "#{sib.name(:ic)}#{sib.anomer}#{link.get_position_for(sib)}#{link.get_position_for(res)}"
              results[disac][:buckets][name] += 1
              disac_count += 1
            }
            if res.parent
              parent_name = res.parent.name(:ic).gsub!(/-ol/,'')
              results[disac][:parent_buckets][res.parent.name(:ic)] += 1
            end
            count += 1
          end
        }
      }
    rescue MonosaccharideException => err
        p err
    ensure
        sug.finish
    end
  end
end
p count
p disac_count
File.open("results.csv","w") do |file|
file << "Linkage,#{all_sibs.keys.sort.join(",")},parents,#{all_parents.keys.sort.join(",")}\n"
results.keys.sort_by{ |d| d[:donor] }.each { |disac|
#  puts "Link: #{disac[:donor]} (#{disac[:anomer]}x-#{disac[:posn]}) #{disac[:substrate]}"
  sibs_string = all_sibs.keys.sort.collect { |name| results[disac][:buckets][name] || 0 }.join(",")
  parents_string = all_parents.keys.sort.collect { |name| results[disac][:parent_buckets][name] || 0 }.join(",") 
  file << ["#{disac[:donor]}(#{disac[:anomer]}x-#{disac[:posn]})#{disac[:substrate]}",sibs_string,' ',parents_string].join(",")
  file << "\n"
}
end