class SvgRenderer
  
  DISPLAY_ELEMENT_NS = "http://penguins.mooh.org/research/glycan-display-0.1"
  SVG_ELEMENT_NS = "http://www.w3.org/2000/svg"
  
  attr_accessor :sugar
  attr_accessor :scheme
  
  def initialise_prototypes
    throw Exception.new("Sugar is not renderable") unless sugar.kind_of? Renderable
    sugar.residue_composition.each { |res|
      res.prototype = XPath.first(res.raw_data_node, "disp:icon[@scheme='#{scheme}']/svg:g", { 'disp' => DISPLAY_ELEMENT_NS, 'svg' => SVG_ELEMENT_NS })
      anchors = Array.new()
      XPath.each(res.raw_data_node, ".//disp:anchor", { 'disp' => DISPLAY_ELEMENT_NS }) { |anchor|
        anchors[anchor.attribute("linkage").value().to_i] = { :x => anchor.attribute("x").value().to_i,
                                                              :y => anchor.attribute("y").value().to_i }
      }
      res.offsets = anchors
      res.size = { :width => 100, :height => 100 }
    }
  end
  
  def render(sugar)
  	doc = Document.new
  	doc.add_element(Element.new('svg:svg'))
  	min_y = nil
  	max_y = nil
  	max_x = nil
  	doc.root.add_attribute('viewBox', '0 -1000 2000 2000')
  	doc.root.add_attribute('version', '1.0')
  	doc.root.add_namespace('svg', SVG_ELEMENT_NS)
  	drawing = doc.root.add_element('svg:g')
  	linkages = drawing.add_element('svg:g')
  	residues = drawing.add_element('svg:g')
    sugar.residue_composition.each { |res|
      el = Document.new(res.prototype.to_s).root
      el.add_attribute('transform',"translate(#{res.position[:x1]+100},#{res.position[:y1]+100}) rotate(180) ")

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
      
      el.add_attribute('width', res.width)
      el.add_attribute('height', res.height)
      residues.add_element el
      res.children.each { |linkage,child|
        line = linkages.add_element('svg:line')
        line.add_attribute('x1',linkage.position[:x1])
        line.add_attribute('y1',linkage.position[:y1])
        line.add_attribute('x2',linkage.position[:x2])
        line.add_attribute('y2',linkage.position[:y2])
        line.add_attribute('stroke-width',3)
        line.add_attribute('stroke','black')        
      }
    }
  	doc.root.add_attribute('viewBox', "0 0 #{max_x} #{max_y}")
  	doc.root.add_attribute('preserveAspectRatio', 'xMinYMin')
  	drawing.add_attribute('transform',"scale(-1,-1) translate(#{-1*max_x},#{-1*max_y})")
    doc.write
  end
  
  def initialize()
    @scheme = "boston"
  end
end