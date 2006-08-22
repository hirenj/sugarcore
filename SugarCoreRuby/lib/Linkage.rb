require 'DebugLog'
require 'SugarException'

class Linkage
	include DebugLog
	
	attr_reader :first_position, :second_position
	attr_reader :first_residue, :second_residue

  def Linkage.Factory( classname, linkage_string )
    linkage  = Linkage.new()
    linkage.extend(classname)
    linkage.read_linkage(linkage_string)
    linkage
  end
  
	public
	
	def set_first_residue( residue, position=@first_position )
		if @first_residue
		  @first_residue.release_attachment_position(@first_position)
		end
		residue.consume_attachment_position(position,self)

    #FIXME - Should not be in here
    residue.anomer = anomer

		@first_residue = residue
		@first_position = position
	end

	def set_second_residue( residue, position=@second_position )
    if @second_residue
		  @second_residue.release_attachment_position(@second_position)
		end
		residue.consume_attachment_position(position,self)
		@second_residue = residue
		@second_position = position
	end

	def get_position_for( residue )
		if residue == @first_residue
			return @first_position
		elsif residue == @second_residue
			return @second_position
		else
			raise LinkageException.new("Residue #{residue} not in linkage")
		end
	
	end
	
	def get_paired_residue( residue )
		if residue == @first_residue
			return @second_residue
		elsif residue == @second_residue
			return @first_residue
		else
			raise LinkageException.new("Residue #{residue} not in linkage")
		end
	end
	
	def finish
		@first_residue = nil
		@second_residue = nil
	end
	
	private
	
end