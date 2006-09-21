class SvgRenderer
  
  DISPLAY_ELEMENT_NS = "http://penguins.mooh.org/research/glycan-display-0.1"
  SVG_ELEMENT_NS = "http://www.w3.org/2000/svg"
  XLINK_NS = "http://www.w3.org/1999/xlink"
  
  attr_accessor :sugar
  attr_accessor :scheme
  attr          :prototypes
  
  
  def initialise_prototypes
    throw Exception.new("Sugar is not renderable") unless sugar.kind_of? Renderable
    nil_mono = Monosaccharide.Factory(sugar.root.class,'Nil')
    [nil_mono, sugar.residue_composition].flatten.each { |res|
      res_id = res.alternate_name(NamespacedMonosaccharide::GS_NAMESPACE)
      prototypes[res_id] = XPath.first(res.raw_data_node, "disp:icon[@scheme='#{scheme}']/svg:g", { 'disp' => DISPLAY_ELEMENT_NS, 'svg' => SVG_ELEMENT_NS })
      if prototypes[res_id] == nil
        prototypes[res_id] = prototypes[nil_mono.alternate_name(NamespacedMonosaccharide::GS_NAMESPACE)]
      end
      
      prototypes[res_id].add_attribute('width', res.width)
      prototypes[res_id].add_attribute('height', res.height)

      anchors = Array.new()
      XPath.each(res.raw_data_node, ".//disp:anchor", { 'disp' => DISPLAY_ELEMENT_NS }) { |anchor|
        anchors[anchor.attribute("linkage").value().to_i] = { :x => 100 - anchor.attribute("x").value().to_i,
                                                              :y => 100 - anchor.attribute("y").value().to_i }
      }
      res.offsets = anchors
      res.dimensions = { :width => 100, :height => 100 }
    }
  end
  
  def render(sugar)
  	doc = Document.new
  	doc.add_element(Element.new('svg:svg'))
  	min_y = nil
  	max_y = nil
  	max_x = nil
  	doc.root.add_attribute('version', '1.1')
  	doc.root.add_attribute('width', '100%')
  	doc.root.add_attribute('height', '100%')
  	doc.root.add_attribute('id', sugar.name)
  	doc.root.add_namespace('svg', SVG_ELEMENT_NS)
  	doc.root.add_namespace('xlink', XLINK_NS)
    definitions = doc.root.add_element('svg:defs')  		
  	drawing = doc.root.add_element('svg:g')
  	linkages = drawing.add_element('svg:g')
  	residues = drawing.add_element('svg:g')
  	
    sugar.residue_composition.each { |res|
      res_id = res.alternate_name(NamespacedMonosaccharide::GS_NAMESPACE)

      icon = nil

      if ( prototypes[res_id] != nil )
        icon = Element.new('svg:use')
        icon.add_attribute('xlink:href' , "##{sugar.name}-proto-#{res_id}")
      end
      if ( res.prototype != nil )
        icon = Document.new(res.prototype.to_s).root
      end
      icon.add_attribute('transform',"translate(#{res.position[:x1]+100},#{res.position[:y1]+100}) rotate(180) ")

      min_y = (min_y == nil)? res.position[:y1] : min_y
      if ( res.position[:y1] < min_y )
        min_y = res.position[:y1]
      end

      max_x = (max_x == nil)? res.position[:x2] : max_x
      if ( res.position[:x2] > max_x )
        max_x = res.position[:x2]
      end

      max_y = (max_y == nil)? res.position[:y2] : max_y
      if ( res.position[:y2] > max_y )
        max_y = res.position[:y2]
      end
      
      if res.labels.length > 0 
        icon.add_attribute('class', res.labels.join(" "))
      end

      
      residues.add_element icon

      res.callbacks.each { |callback|
        callback.call(icon)
      }

      
      res.children.each { |linkage,child|
        line = linkages.add_element('svg:line')
        line.add_attribute('x1',linkage.position[:x1])
        line.add_attribute('y1',linkage.position[:y1])
        line.add_attribute('x2',linkage.position[:x2])
        line.add_attribute('y2',linkage.position[:y2])
        line.add_attribute('stroke-width',3)
        line.add_attribute('stroke','black')
        if linkage.labels.length > 0
          line.add_attribute('class', linkage.labels.join(" "))
        end
        linkage.callbacks.each { |callback|
          callback.call(line)
        }
      }
    }
    prototypes.each { |key,val|
      proto_copy = Document.new(val.to_s).root
      proto_copy.add_attribute('id', "#{sugar.name}-proto-#{key}")
      proto_copy.add_attribute('class', "#{key}")
      definitions.add_element(proto_copy)
    }
        
  	doc.root.add_attribute('viewBox', "0 0 #{max_x+100} #{max_y+100+(max_y - min_y)}")
  	doc.root.add_attribute('preserveAspectRatio', 'xMinYMin')
  	drawing.add_attribute('transform',"scale(-1,-1) translate(#{-1*(max_x+100)},#{-1*(max_y+100)})")
    return doc
  end
  
  def initialize()
    @scheme = "boston"
    @prototypes = Hash.new()
  end
end