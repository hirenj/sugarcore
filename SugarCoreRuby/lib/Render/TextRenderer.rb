require 'DebugLog'
require 'Render/AbstractRenderer'

class TextRenderer
  include AbstractRenderer
  include DebugLog
  
  def initialise_prototypes()
  end

  def render(sugar)
    case scheme
      when :ic
        error("Rendering as iupac condensed")
        sugar.extend(Sugar::IO::CondensedIupac::Writer)
        sugar.target_namespace = NamespacedMonosaccharide::NAMESPACES[:ic]
      when :ecdb
        sugar.extend(Sugar::IO::GlycoCT::Writer)
    end
    return sugar.sequence
  end

  def initialize()
  end
  
end
