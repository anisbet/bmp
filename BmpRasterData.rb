######################################
#
# File:     BmpCompression.rb.
# Purpose:  Abstraction of a BMP RLE 
#           compression algorithm.
# Version:  0.1
# Date:     January 24, 2006
# Author:   Andrew Nisbet
#
######################################

module Bmp

require "BmpGeometry"

#
# Abstraction of the BMP raster data section.
#
class BmpData
	def initialize(bmp, file)
		@bmp = bmp
		# Go to the beginning of the bmp data.
		file.seek(@bmp.bitmapDataOffset, IO::SEEK_SET)
		@bmpDataArray = Array.new
		@bmpDataArray = file.read(@bmp.bitmapDataSize())
		#dataArray = file.read(@bmp.bitmapDataSize())
		if @bmp.compression == 1    #RLE_4
		#	 decompress_4(file)
		elsif @bmp.compression == 2 #RLE_8
		#	 decompress_8(file)
		else # none
		#	@bmpDataArray = decompress_0(dataArray)
		end		
	end # end def
	
	
	#
	# Writes the BMP raster data to file.
	#
	def write(file)
		@bmpDataArray.each do |data|
			file.write(data)
		end
	end
	
	#
	# Inverts the pixels in the bmp data section. The pixel object
	# 'knows' if this makes sense to do or not and may quietly ingnore
	# the request.
	#
	def xor
		pixelFactory = PixelFactory.new(@bmp)
		pixel = pixelFactory.getPixel()
		while pixel.hasNextPixel do
			pixel.nextPixel
			pixel.xor
		end
	end
	
	attr_accessor :bmpDataArray
	
protected
	#
	# Reads the bmp data into a two dimensional array of values.
	#
	def decompress_0(array)
		newArray = Array.new
		for i in 0 .. (@bmp.height() -1) do
			newArray << array.slice((i * @bmp.width), ((i * @bmp.width) + @bmp.width))
		end
		return newArray
	end
	
	#
	# Compresses the data (or not if compression is set to none). Typically called 
	# from the write method.
	#
	def compress_4(file)

	end
	
	#
	# Reads the bmp data into a two dimensional array of values.
	#
	def decompress_4(file)
		index = 0
		# read two bytes; the first is the repeat count the second the nibble indexes to the palette.
	end
	
end # end internal class BmpData
end # module.