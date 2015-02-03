######################################################
#
# File:     BmpPacker.rb.
# Purpose:  Abstraction of a steganographic BMP file.
# Version:  0.1
# Date:     February 6, 2006
# Author:   Andrew Nisbet
#
######################################################

module Bmp

#
# General BmpPacking exception.
#
class BmpPackerError < RuntimeError
	def initialize(msg)
		$stderr.puts "BmpPackerError: #{msg}"
	end
end


#
# This class handles the packing of data from the source file to the destination file.
# How password protection works. The reserved field indicates that there is data already
# hidden in the file. If you clear the reserved field the data is essentially lost because
# another imaging application could have altered the file since the original file was
# encoded. The first byte stored is the size of the password, the second is the size of
# the file name. The next 32 bits are the length of the encoded data. After that is the
# password, the file name and then the first byte of the file.
#
class BmpPacker

	#
	# Constructor.
	#
	def initialize(bmpFile)
		@bmp = bmpFile
		@data = bmpFile.bitmapData.bmpDataArray
		@index = 0               # index to the bmp's data array section.
		@eofileOffset = 0        # decode only, offset of the end of the encoded file.
		@fileName = ""           # decode only
	end
	
	#
	# Retrieves the password from the bmp and checks it against the stored value.
	#
	def validatePassword(password)
		passwordLength = unpackByte
		fileNameLength = unpackByte
		@eofileOffset = unpackInteger
		if password != unpackString(passwordLength)
			return false
		end
		@fileName = unpackString(fileNameLength)
		return true
	end
	
	#
	# Decodes an encoded file from a BMP.
	#
	def decode
		fileContent = Array.new
		for i in 0 .. @eofileOffset do 
			fileContent << unpackByte() 
		end
		
		fileOut = open(@fileName, "wb")
		fileOut.write(fileContent.pack("C*"))
		fileOut.close
	
		@bmp.reserved = 0
		@bmp.write
	end
	
	#
	# Encodes the argument file name to the BMP.
	#
	def encode(password, encodeFileName)
		encodedFileSize = File.size(encodeFileName)
		# set the stegoed data flag.
		@bmp.reserved = 1
		# Pack the header (pwd len, fileName len, EOF offset, password and file name.)
		packByte(password.size)
		packByte(encodeFileName.size)
		packInteger(encodedFileSize)
		packString(password)
		packString(encodeFileName)
		# pack data
		file = open(encodeFileName, "rb")
		file.each_byte do |byte|
			packByte(byte)
		end
		file.close
		# write the bmp
		@bmp.write
	end
	
	attr_reader :fileName # will be nil if using encode mode.
	
private

	#
	# This method takes the arg byte and encodes it into the next 8 bytes of the BMP data.
	#
	def packByte(byte)
		bit = Array.new
		bit[0] = ((byte & 0x80) >> 7)
		bit[1] = ((byte & 0x40) >> 6)
		bit[2] = ((byte & 0x20) >> 5)
		bit[3] = ((byte & 0x10) >> 4)
		bit[4] = ((byte & 0x08) >> 3)
		bit[5] = ((byte & 0x04) >> 2)
		bit[6] = ((byte & 0x02) >> 1)
		bit[7] =  (byte & 0x01)
		
		for i in 0 .. 7 do
			# Flip the bit 0 .. 7th bit value to the value but only if they differ
			lastBit = (@data[@index] & 0x01)
			if lastBit != bit[i]
				a = (@data[@index] & 0xFE)
				if lastBit == 1
					@data[@index] = a
				else
					@data[@index] = a + 1
				end
			end
			@index += 1
		end
	end
	
	#
	# Returns an encoded byte from the BMP data array.
	#
	def unpackByte
		# to get the data out we grab the next 8 bytes from the BMP and strip off
		# the last bits and make a byte out of them.
		bit = Array.new
		for i in 0 .. 7 do
			a = (@data[@index] & 0x01) # Strip the last bit off this array value
			bit[i] = a                 # Store the bit.
			@index += 1
		end
		# decode the bit values.
		num = 0
		bit.reverse!
		for i in 0 .. 7 do
			num += (bit[i].to_i * (2 ** i))
		end
		
		return num
	end
	
	#
	# Packs an integer DWORD or 32 bit value into the next 32 bytes of bmp data.
	#
	def packInteger(integer)
		a = ((integer & 0xFF000000) >> 24)
		packByte(a)
		a = ((integer & 0x00FF0000) >> 16)
		packByte(a)
		a = ((integer & 0x0000FF00) >> 8)
		packByte(a)
		a =  (integer & 0x000000FF)
		packByte(a)		
	end
	
	#
	# Unpacks an integer DWORD or 32 bit value into the next 32 bytes of bmp data.
	#
	def unpackInteger
		a = unpackByte
		integer = (a << 24)
		a = unpackByte
		integer += (a << 16)
		a = unpackByte
		integer += (a << 8)
		a = unpackByte
		integer += a
		
		return integer
	end
	
	#
	# This method takes the arg string and encodes it into the bmp.
	#
	def packString(str)
		size = str.size -1
		for i in 0 .. size do
			packByte(str[i])
		end
	end
	
	#
	# Gets the string value from a encoded bmp file.
	#
	def unpackString(size)
		str = ""
		for i in 0 .. (size -1) do
			str << unpackByte
		end
		return str
	end
end # end of BmpPacker class
end # module