######################################
#
# File:     BMP.rb.
# Purpose:  Abstraction of a BMP file.
# Version:  0.1
# Date:     January 24, 2006
# Author:   Andrew Nisbet
#
######################################

module Bmp

require "BmpRasterData"

#
# General bmp exception.
#
class BmpError < RuntimeError
	def initialize(msg)
		$stderr.puts "BmpError: #{msg}"
	end
end # BmpError Class


#
# This class is the basic abstract view of a BMP file.
#
class BmpFile

	#
	# Constructor for BMP file.
	#
	def initialize(name)
		if ! File.exist?(name)
			raise BmpError.new(name + " not found. Exiting.")
		end
		@name             = name # name of bmp file
		begin
		
		bFileIn           = open(@name, "rb")
		@id               = ""  # type of bmp
		if ! read_id(bFileIn)
			raise BmpError.new(@name + " is not a valid BMP file.")
		end
		@fileSize         = read_int(bFileIn) # size of the file
		@reserved         = read_int(bFileIn) # reserved word; '0' unless a file is embedded.
		@bitmapDataOffset = read_int(bFileIn) # offset to the bitmap data
		@bitmapHeaderSize = read_int(bFileIn) # size of the header
		@width            = read_int(bFileIn) # width of the image
		@height           = read_int(bFileIn) # height of the image
		@planes           = read_short(bFileIn) # number of planes in the image
		@bitsPerPixel     = read_short(bFileIn) # depth of colour; amount of information stored about a single pel.
		@compression      = read_int(bFileIn) # type of compression used in the bitmap data
		@bitmapDataSize   = read_int(bFileIn) # size of the bitmap data
		@hRes             = read_int(bFileIn) # horizontal resolution of the image
		@vRes             = read_int(bFileIn) # vertical resolution of the image
		@colours          = read_int(bFileIn) # number of colours in the image
		@importantColours = read_int(bFileIn) # number of most significant colours in the image
		@palette          = read_palette(bFileIn) # palette's data structure 24 bit and above bmps don't have.
		#if @compression == 1 || compression == 2
			#raise BmpError.new("compression type 1 or 2 not supported yet.")
		#end
		@bitmapData       = BmpData.new(self, bFileIn) # data structure of the bmp image data.
		
		rescue
		$stderr.puts "Error reading bmp."
		raise
		ensure
		bFileIn.close
		end # exception
	end # end initialize
	
	#
	# Returns the name of the bmp file.
	#
	def to_s
		return "BmpFile: '#{@name}'"
	end
	
	#
	# Returns the string description of compression.
	#
	def getCompression
		case @compression
		when 0
			return "BI_RGB"
		when 1
			return "BI_RLE4"
		when 2
			return "BI_RLE8"
		when 3
			return "BI_BITFIELDS"
		end # case
	end
	
	#
	# Returns a text string indicating the number of bits per pixel.
	#
	def getBitsPerPixel
		case @bitsPerPixel
		when 1
			return "MONOCHROME"
		when 4
			return "16_COLOURS"
		when 8
			return "256_COLOURS"
		when 16
			return "65535_COLOURS"
		when 24
			return "TRUE_COLOUR_24"
		when 32
			return "TRUE_COLOUR_32"
		end # case	
	end
	
	
	#
	# Re-writes the bmp file back out.
	#
	def write
		begin
		
		# Reopen bmp for writing.
		bFileOut = open(@name, "wb")
		# write the header info
		bFileOut.write("BM")
		a = [@fileSize, @reserved, @bitmapDataOffset,
		     @bitmapHeaderSize, @width, @height, 
		     @planes, @bitsPerPixel,                  # Short values
		     @compression, @bitmapDataSize, @hRes,
		     @vRes, @colours, @importantColours
			]
		bFileOut.write(a.pack("I6S2I6"))
		# write the palette (if any)
		writePalette(bFileOut)
		# write the bmp data.
		@bitmapData.write(bFileOut)
		# close the stream.
		bFileOut.close
		
		rescue Errno::EACCES
		$stderr.puts "can't write because the file is in use by another process."
		raise
		rescue
		$stderr.puts "Error writing '#{@name}'."
		raise
		ensure
		if ! bFileOut.nil? && ! bFileOut.closed?
			bFileOut.close
		end
		end # exception
	end
	
	#
	# This inverts or creates a negative of a bmp.
	#
	def xor
		# determine which type of bmp
		if @bitsPerPixel < 16
			# xor the byte values or palette entries as required.
			invert_palette
		else
			# xor the colour information in each of the pixels.
			@bitmapData.xor
		end
		# re-write the file.
		write
	end
	
	#
	# Reads one of the 'c' primitive types of int
	#
	def read_int(file)
		intVal = ""
		4.times do
			intVal << file.getc 
		end
		
		return intVal.unpack('I*')[0]
	end
	
	#
	# Reads a 'c' short value (2 bytes).
	#
	def read_short(file)
		shortVal = ""
		2.times do
			shortVal << file.getc 
		end
		# returns unsigned short ('S')
		return shortVal.unpack('S*')[0]
	end
	
	
	attr_reader :name, :fileSize, :bitmapDataOffset, :bitmapHeaderSize, :width,
				:height, :planes, :bitsPerPixel, :compression, :bitmapDataSize, :hRes,
				:vRes, :colours, :importantColours, :palette 
				
	attr_accessor :reserved, :bitmapData


#################################
protected
	
	#
	# This method reads the palette if any. The underlying structure is an Array.
	#
	def read_palette(file)
		paletteSize = 0
		
		if @bitsPerPixel == 1
			paletteSize = 2
		elsif @bitsPerPixel == 4
			if @colours < 16
				paletteSize = @colours
			else
				paletteSize = 16
			end
		elsif @bitsPerPixel == 8
			if @colours < 256
				paletteSize = @colours
			else
				paletteSize = 256
			end
		elsif @bitsPerPixel == 16
			if getCompression == "BI_RGB"
				paletteSize = 0
			elsif getCompression == "BI_BITFIELDS"
				paletteSize = 3 # One for each mask of blue green and red.
			end
		end
		
		# A palette for BMPs with BitsPerPixel of 16, 24 or 32 have a size of 0.
		myPalette = Array.new
		paletteSize.times do
			myPalette << BmpPalette.new( file )
		end
			
		return myPalette
	end
	
	
	#
	# Inverts the colours in the palette.
	#
	def invert_palette
		@palette.each do |paletteEntry|
			paletteEntry.xor
		end
	end
	
	
	#
	# Reads the id, tests and returns true if the file is a valid BMP and false otherwise.
	#
	def read_id(file)
		# reads two bytes
		2.times do 
			@id << file.getc 
		end
		
		# test the two bytes.
		if @id == "BM"
			return true
		end 
		return false
	end # read_id
	
	#
	# Writes the palette contents (if any) to file.
	#
	def writePalette(file)
		@palette.each do |paletteEntry|
			file.write(paletteEntry.write)
		end
	end
end # end Class BmpFile.

end # end Module