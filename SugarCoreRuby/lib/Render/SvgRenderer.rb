require 'DebugLog'
require 'Render/AbstractRenderer'

class SvgRenderer
  include DebugLog
  include AbstractRenderer
  
  DISPLAY_ELEMENT_NS = "http://penguins.mooh.org/research/glycan-display-0.1"
  SVG_ELEMENT_NS = "http://www.w3.org/2000/svg"
  XLINK_NS = "http://www.w3.org/1999/xlink"
  
  attr_reader :min_y,:max_x,:max_y
  
  def use_prototypes?
    @use_prototypes
  end
    
  def dont_use_prototypes
    debug("Switching off prototypes")
    @use_prototypes = false
  end
  
  def min_y=(min_y)
    if @min_y == nil
      @min_y = min_y
    else
      if min_y < @min_y
        @min_y = min_y
      end
    end
  end

  def max_y=(max_y)
    if @max_y == nil
      @max_y = max_y
    else
      if max_y > @max_y
        @max_y = max_y
      end
    end
  end

  def max_x=(max_x)
    if @max_x == nil
      @max_x = max_x
    else
      if max_x > @max_x
        @max_x = max_x
      end
    end
  end

    
  def initialise_prototypes
    throw Exception.new("Sugar is not renderable") unless sugar.kind_of? Renderable
    nil_mono = Monosaccharide.Factory(sugar.root.class,'ecdb:nil')
    nil_mono.extend(Renderable::Residue)
    [nil_mono, sugar.residue_composition].flatten.each { |res|
      res_id = res.name(NamespacedMonosaccharide::NAMESPACES[:ecdb])
      prototypes[res_id] = XPath.first(res.raw_data_node, "disp:icon[@scheme='#{scheme}']/svg:g", { 'disp' => DISPLAY_ELEMENT_NS, 'svg' => SVG_ELEMENT_NS })
      if prototypes[res_id] == nil
        prototypes[res_id] = prototypes[nil_mono.name(NamespacedMonosaccharide::NAMESPACES[:ecdb])]
      end
      
      prototypes[res_id].add_attribute('width', res.width)
      prototypes[res_id].add_attribute('height', res.height)

      anchors = Hash.new()
      XPath.each(res.raw_data_node, "./disp:icon[@scheme='#{scheme}']/disp:anchor", { 'disp' => DISPLAY_ELEMENT_NS }) { |anchor|
        anchors[anchor.attribute("linkage").value().to_i] = { :x => 100 - anchor.attribute("x").value().to_i,
                                                              :y => 100 - anchor.attribute("y").value().to_i }
      }
      if anchors.empty?
        anchors = nil_mono.offsets
      end
      res.offsets = anchors
      res.dimensions = { :width => 100, :height => 100 }
    }
  end
  
  def render(sugar)
    return render_sugar(sugar)
  end
  
  def render_sugar(sugar)
  	doc = Document.new
  	doc.add_element(Element.new('svg:svg'))
  	doc.root.add_attribute('version', '1.1')
  	doc.root.add_attribute('width', '100%')
  	doc.root.add_attribute('height', '100%')
  	if (width != nil && height != nil)
    	doc.root.add_attribute('width', width)
    	doc.root.add_attribute('height', height)  	  
	  end
  	doc.root.add_attribute('id', sugar.name)
  	doc.root.add_namespace('svg', SVG_ELEMENT_NS)
  	doc.root.add_namespace('xlink', XLINK_NS)
    
    definitions = doc.root.add_element('svg:defs')
    
  	drawing = doc.root.add_element('svg:g')
  	linkages = drawing.add_element('svg:g')
  	residues = drawing.add_element('svg:g')
  	
  	icons = Array.new()
  	
    sugar.residue_composition.each { |res|

      icons << render_residue(res)

      res.children.each { |child|
        linkages.add_element(render_link(child[:link]))
      }

    }
    
    icons.sort_by { |icon|
      icon.get_elements('svg:text').length > 0 ? 1 : 0
    }.each { |ic|
      residues.add_element ic
    }
    
    
    if ( self.use_prototypes? )    
      prototypes.each { |key,val|
        proto_copy = Document.new(val.to_s).root
        proto_copy.add_attribute('id', "#{sugar.name}-proto-#{key}")
        proto_copy.add_attribute('class', "#{key}")
        definitions.add_element(proto_copy)
      }
    end
    
  	doc.root.add_attribute('viewBox', "0 0 #{self.max_x+100} #{self.max_y+100+(self.max_y - self.min_y)}")
  	doc.root.add_attribute('preserveAspectRatio', 'xMinYMin')
  	drawing.add_attribute('transform',"scale(-1,-1) translate(#{-1*(self.max_x+100)},#{-1*(self.max_y+100)})")
    return doc
  end

  def render_link(linkage)
    if (scheme == 'oxford' && linkage.is_unknown? )
      line = render_curvy_link(linkage)      
    else
      line = render_straight_link(linkage)
    end

    line.add_attribute('stroke-width',3)
    line.add_attribute('stroke','black')
    line.add_attribute('fill','none')
    if (scheme == 'oxford' && linkage.reducing_end_substituted_residue.anomer == 'a')
      line.add_attribute('stroke-dasharray', '6,6')
    end
    
    if linkage.labels.length > 0
      line.add_attribute('class', linkage.labels.join(" "))
    end
    linkage.callbacks.each { |callback|
      callback.call(line)
    }
    return line    
  end

  def render_curvy_link(linkage)
    line = Element.new('svg:path')
    centre = linkage.centre
    quad = {}
    quad[:x] = linkage.position[:x1] + 50
    quad[:y] = linkage.position[:y1] + 50
    p1 = "#{linkage.position[:x1]},#{linkage.position[:y1]}"
    p2 = "#{quad[:x]},#{quad[:y]}"
    p3 = "#{centre[:x]},#{centre[:y]}"
    p4 = "#{linkage.position[:x2]},#{linkage.position[:y2]}"
    line.add_attribute('d', "M#{p1} Q#{p2} #{p3} T#{p4}")
    return line
  end

  def render_straight_link(linkage)
    line = Element.new('svg:line')
    line.add_attribute('x1',linkage.position[:x1])
    line.add_attribute('y1',linkage.position[:y1])
    line.add_attribute('x2',linkage.position[:x2])
    line.add_attribute('y2',linkage.position[:y2])
    return line
  end
  
  def render_residue(res)

    res_id = res.name(NamespacedMonosaccharide::NAMESPACES[:ecdb])

    icon = nil

    if ( prototypes[res_id] != nil )
      icon = Element.new('svg:use')
      icon.add_attribute('xlink:href' , "##{sugar.name}-proto-#{res_id}")
    end

    if ( ! self.use_prototypes? )
      icon = Document.new(prototypes[res_id].to_s).root
    end
    
    if ( res.prototype != nil )
      icon = Document.new(res.prototype.to_s).root
    end
    
    icon.add_attribute('transform',"translate(#{res.position[:x1]+100},#{res.position[:y1]+100}) rotate(180) ")

    self.min_y = res.position[:y1]
    self.max_x = res.position[:x2]
    self.max_y = res.position[:y2]
        
    if res.labels.length > 0 
      icon.add_attribute('class', res.labels.join(" "))
    end
    
    res.callbacks.each { |callback|
      callback.call(icon)
    }
    
    return icon
  end
  
  protected :render_sugar, :render_link, :render_residue
  
  def initialize()
    @scheme = "boston"
    @prototypes = Hash.new()
    @use_prototypes = true
  end
end