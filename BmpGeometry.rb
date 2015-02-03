###################################################
#
# File:     BmpGeometry.rb.
# Purpose:  Abstraction of the BMP's raster data.
# Version:  0.1
# Date:     January 30, 2006
# Author:   Andrew Nisbet
#
###################################################

module Bmp
#
# RGB quad is an abstraction of a pixel or palette entry. Pixels have a 
# Red Green and Blue byte. Palettes have these too but they also have
# a reserved filler byte. It's upto the implementing class to remember
# what type they are.
#
class BmpPalette
	
	#
	# Takes the BMP file and 
	#
	def initialize(file)
		@blue  = file.getc
		@green = file.getc
		@red   = file.getc
		@fill  = file.getc
	end
	
	#
	# Prints the contents of the palette entry.
	#
	def inspect
		return printf("< blue:0x%02x, green:0x%02x, red:0x%02x, fill:0x%02x >\n", @blue, @green, @red, @fill)
	end
	
	#
	# Returns a string version of the palette entry.
	#
	def to_s
		out = "< blue:" + @blue.to_s 
		out += " green:" + @green.to_s 
		out += " red:" + @red.to_s 
		out += " fill:" + @fill.to_s + " >\n"
		return out
	end
	
	#
	# Returns a binary formatted version of this object, ready for serialization.
	#
	def write
		a = [ @blue, @green, @red, @fill ]
		return a.pack("C4")
	end
	
	#
	# This method will xor the palette entry using a logical xor function.
	#
	def xor(hex = 0xFF)
		@blue  ^= hex
		@green ^= hex
		@red   ^= hex
	end
	
	attr_accessor :blue, :green, :red, :fill
end



#
# The basic abstraction of a bmp pixel without having to worry about
# underlying implementation. The class behaves as you would expect.
#
class Pixel
protected
	def initialize(array)
		@blue     = 0
		@green    = 0
		@red      = 0
		@paletteIndex = 0       # Index to an entry in the palette (optional).
		@array    = array
		@bmpSize  = array.size
		@bmpIndex = -1          # So getNextPixel returns pixel zero.
	end

public
	#
	# Returns the blue component of the pixel. If there is none, as is the 
	# case of a monochrome image, the stored value of the pixel is returned.
	#
	attr_accessor :blue, :green, :red, :paletteIndex
	
	def inspect
		return "<blue:#{blue}, green:#{green}, red:#{red}>\n" 
	end
	
	def to_s
		return "<blue:" + @blue.to_s + ", green:" + @green.to_s + ", red:" + @red.to_s + ">\n" 
	end
	
	#
	# This method does nothing because the pixels that need this feature
	# implement it as required. The majority use a byte to represent the
	# index to the colour palette not for colour information.
	#
	def xor(hex = 0xFF)
		# intentionally left blank.
	end

	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		# intensionally left blank.
	end
	
	#
	# Returns true if there is another pixel in the array and false otherwise.
	#
	def hasNextPixel
		if @bmpIndex < @bmpSize
			return true
		end
		return false
	end
end # end Pixel



#
# RGBNibble is an abstraction of 4 bit index to a record in the colour palett.
# In this respect it is not a pixel at all but behaves as one for consistancy.
#
class RGBNibble < Pixel
	def initialize(array)
		super(array)
	end
	
	#
	# Returns the high order nibble if arg order is 1 or greater and returns the low order
	# nibble otherwise.
	#
	def getNibble(order)
		if order >= 1
			return ((@paletteIndex & 0xF0) >> 4)
		end
		return (@paletteIndex & 0x0F)
	end
	
	def inspect
		return @paletteIndex
	end
	
	def to_s
		return @paletteIndex.to_s
	end

	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end
		@bmpIndex += 1
		@paletteIndex = @array[@bmpIndex]
	end
end

#
# RGBByte is an abstraction of 8 bit index to a record in the colour palette.
# In this respect the pixel does not represent colour information.
#
class RGBByte < Pixel
	def initialize(array)
		super(array)
	end
	
	def inspect
		return @paletteIndex
	end
	
	def to_s
		return @paletteIndex.to_s
	end
	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end
		@bmpIndex += 1
		@paletteIndex = @array[@bmpIndex]
	end
end


#
# RGBBit is an abstraction of 8 pixels in a monochrome bmp.
#
class RGBBit < RGBByte
	def initialize(array)
		super(array)
	end
	
	# 
	# Returns requested bit value or nil if the bit number is out of range.
	# The underlying structure is a byte and the least significant bit is '0'.
	#
	def getBit(which)
		case which
		when 7
			return ((@paletteIndex & 0x80) >> 7)
		when 6
			return ((@paletteIndex & 0x40) >> 6)
		when 5
			return ((@paletteIndex & 0x20) >> 5)
		when 4
			return ((@paletteIndex & 0x10) >> 4)
		when 3
			return ((@paletteIndex & 0x08) >> 3)
		when 2
			return ((@paletteIndex & 0x04) >> 2)
		when 1
			return ((@paletteIndex & 0x02) >> 1)
		when 0
			return ( @paletteIndex & 0x01)
		else
			return nil
		end
	end # getBit

	def to_s
		return @paletteIndex.to_s
	end
	
	#
	# This method will xor the pixels bits using a logical xor function.
	#
	def xor(hex = 0xFF)
		if hasNextPixel == false
			return
		end
		@paletteIndex ^= 255
		@array[@bmpIndex] = @paletteIndex
	end
	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end
		@bmpIndex += 1
		@paletteIndex = @array[@bmpIndex]
	end
end  # end RGBBit


#
# RGBWord is an abstraction of 4 bit pixel in a 4bit bmp.
#
class RGBWord < Pixel
	def initialize(array)
		super(array)
	end
	
	#
	# This method will xor the palette entry using a logical xor function.
	#
	def xor(hex = 0xFFFF)
		if hasNextPixel == false
			return
		end
		@paletteIndex ^= hex
		@blue = (@paletteIndex & 0x1F)
		@green= ((@paletteIndex & 0x3E) >> 5)
		@red  = ((@paletteIndex & 0x7C) >> 10)
		@array[(@bmpIndex -1)] = ((@paletteIndex & 0xFF00) >> 8)
		@array[@bmpIndex] = (@paletteIndex & 0x00FF)
	end
	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end
		@bmpIndex += 1
		# This pixel is two bytes wide.
		a = [ @array[@bmpIndex], @array[(@bmpIndex +1)] ]
		@paletteIndex = a.unpack('S*')[0]
		@blue = ( @paletteIndex & 0x1F)
		@green= ((@paletteIndex & 0x3E) >> 5)
		@red  = ((@paletteIndex & 0x7C) >> 10)
	end	
end

#
# RGB quad is an abstraction of a pixel in a 32 bit colour bmp. In this
# type of geometry, each red, green or blue part of a pixel is represented
# by a 32 bit Integer. The most significant 8 bits are empty. We read this
# object as four bytes.
#
class RGBQuad < Pixel
	def initialize(array)
		super(array)
	end
	
	#
	# This method will xor the palette entry using a logical xor function. Each
	# channel (RGB except alpha) of the bmp will be xored. 
	#
	def xor(hex = 0xFF)
		if hasNextPixel == false
			return
		end
		# @alpha ^= hex
		@blue  ^= hex
		@green ^= hex
		@red   ^= hex
		@array[(@bmpIndex -3)] = @alpha
		@array[(@bmpIndex -2)] = @blue
		@array[(@bmpIndex -1)] = @green
		@array[ @bmpIndex ]    = @red
	end
	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end
		@bmpIndex += 1
		@alpha = @array[bmpIndex]
		@bmpIndex += 1
		@blue  = @array[bmpIndex]
		@bmpIndex += 1
		@green = @array[bmpIndex]
		@bmpIndex += 1
		@red   = @array[bmpIndex]
	end
	
	attr_accessor :alpha
end

#
# RGBTriple is an abstraction of a pixel for a 24 bit colour BMP.
# In this type, each byte stores a value for Blue, Green and Red
# respectively.
#
class RGBTriple < Pixel
	#
	# Reads three bytes from the file.
	#
	def initialize(array)
		super(array)
	end

	#
	# This method will xor the palette entry using a logical xor function.
	#
	def xor(hex = 0xFF)
		if hasNextPixel == false
			return
		end
		@blue  ^= hex
		@green ^= hex
		@red   ^= hex
		@bmpIndex -= 2
		@array[@bmpIndex] = @blue
		@bmpIndex += 1
		@array[@bmpIndex] = @green
		@bmpIndex += 1
		@array[@bmpIndex] = @red
	end
	
	#
	# Moves the pixel frame to the next pixel.
	#
	def nextPixel
		if hasNextPixel == false
			return
		end

		@bmpIndex += 1
		@blue  = @array[@bmpIndex]
		@bmpIndex += 1
		@green = @array[@bmpIndex]
		@bmpIndex += 1
		@red   = @array[@bmpIndex]
	end
end


#
# This class is a factory that creates pixels of the correct type based on the data
# provided.
#
class PixelFactory

	@pixel = nil  # singleton instance
	@array = nil
	def initialize(bmp)
		@size = bmp.bitsPerPixel
		@array = bmp.bitmapData.bmpDataArray
	end
	
	#
	# Returns an array of pixels. In the overwhelming number of cases the array
	# will contain only one element, but in the case of 4 bit or monochrome
	# the pixel will contain 2 elements and 8 elements respectively.
	#
	def getPixel()		
		if ! @pixel.nil?
			return @pixel
		end
		
		case @size
		when 1  # monochrome each bit of a byte is a pixel.
			@pixel = RGBBit.new(@array)
		when 4  # sixteen colours.
			@pixel = RGBNibble.new(@array)
		when 8  # 256 colours, a single byte each.
			@pixel = RGBByte.new(@array)
		when 16 # 65,536 colours
			@pixel = RGBWord.new(@array)
		when 24 # 16 million colours (true colour).
			@pixel = RGBTriple.new(@array)
		when 32 # I can't find any application that can make these
			@pixel = RGBQuad.new(@array)			
		end # end case
		return @pixel
	end
end # end PixelFactory

end #end module