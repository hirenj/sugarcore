require 'DebugLog'

class Linkage
	include DebugLog
	
	attr_reader :first_position, :second_position
	attr_reader :first_residue, :second_residue

	def initialize( first_residue, first_position, 
					second_residue, second_position )

		info "Creating a linkage between #{first_position} on "+
			 "#{first_residue.name} and #{second_position} on "+
			 "#{second_residue.name}"
			 
		@first_position = first_position
		@first_residue = first_residue
		
		first_residue.consume_attachment_position(first_position, self)
		
		@second_position = second_position
		@second_residue = second_residue
		
		second_residue.consume_attachment_position(second_position, self)
	end

	public
	
	def set_first_residue( position, residue )
		@first_residue.release_attachment_position(@first_position)
		residue.consume_attachment_position(position,self)
		@first_residue = residue
		@first_position = position
	end

	def set_second_residue( position, residue )
		@second_residue.release_attachment_position(@second_position)
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
			# FIXME - THROW AN EXCEPTION
			return 0
		end
	
	end
	
	def get_paired_residue( residue )
		if residue == @first_residue
			return @second_residue
		elsif residue == @second_residue
			return @first_residue
		else
			#THROW EXCEPTION
			return 0
		end
	end
	
	private
	
end


class GlycosidicLinkage < Linkage

	attr_accessor :anomer

	def initialize( first_residue, first_position, 
					second_residue, second_position,
					anomer )
		super(first_residue, first_position, second_residue, second_position)
		@anomer = anomer
	end

	public
	def to_sequence
		return self.anomer + self.first_position + '-' + self.second_position
	end
end