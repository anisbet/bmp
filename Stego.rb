######################################################
#
# File:     Stego.rb.
# Purpose:  Abstraction of a steganographic BMP file.
# Version:  0.1
# Date:     February 6, 2006
# Author:   Andrew Nisbet
#
######################################################

module Bmp
require "Bmp"
require "BmpPacker"

#
# General Stego exception.
#
class SteganographicError < RuntimeError
	def initialize(msg)
		$stderr.puts "SteganographicError: #{msg}"
	end
end


#
# This class represents a BMP file that is capable of storing or hiding
# other data within a BMP file. The only files that can take advantage
# of this technology are 24 bit BMP files, but you can store any type
# of data inside the BMP (text, mp3s, other graphics whatever), you are
# limited by the size of the BMP file as to the size of the data you 
# can store. The files can be password protected.
#
# Parameter destFile: The target BMP file that will act as the storage container
# Parameter srcFile: The data that will be stored in the BMP.
#
class Stego < BmpFile

	#
	# Constructor for packing a file 
	#
	def initialize(password, bmpFile, srcFile)
		super(bmpFile)
		
		if srcFile.nil?
			# test for encoded data.
			if reserved == 0
				raise SteganographicError.new("no embedded data to decode.")
			end
			bmpPacker = BmpPacker.new(self)
			if bmpPacker.validatePassword(password) == false
				raise SteganographicError.new("incorrect password.")
			end
			puts "unpacking: " + bmpPacker.fileName + " from " + name + "."
			bmpPacker.decode
		else
			# an exception is thrown if any of these tests fails.
			testBmpFile
			testSrcFile(srcFile, password)
			testPasswordSize(password)
			puts "packing: " + srcFile + " into " + name + "."
			bmpPacker = BmpPacker.new(self)
			bmpPacker.encode(password, srcFile)
		end # end if
	end
	
private
	#
	# Throws an exception if the password is greater than 255 characters in length.
	# passed
	def testPasswordSize(password)
		if password.size > 255
			raise SteganographicError.new("Password too large; maximum 255 characters")
		end
	end
	
	
	#
	# Tests if the file to encode can be stored in the destination BMP.
	# passed
	def testSrcFile(sourceFile, password)
		# the file must be bigger than 0 bytes and less than the number of RGB elements
		# of the destination BMP. We also must factor in the initial password size byte value
		# and the password (if any). We can store three bits for every RGB element.
		#   pwd length byte   pwd    file Name len file name end offset    encode file size.
		@DataSize = 1 + password.size + 1 + sourceFile.size + 4 + File.size(sourceFile)
		if File.size(sourceFile) == 0
			raise SteganographicError.new("The source file has 0 bytes.")			
		elsif ((@DataSize * 8) > bitmapDataSize)
			msg = "The BMP has can hold " + (bitmapDataSize / 8).to_s + 
				" bytes; data size = " + @DataSize.to_s + " bytes."
			raise SteganographicError.new(msg)
		end
		# check the size of the encoded file name.
		if sourceFile.size > 255
			raise SteganographicError.new("Source file name too large; maximum 255 characters")
		end
	end
	
	
	#
	# This method performs various tests on the destination BMP to see if it qualifies as
	# a candidate for the steganographic process.
	# passed
	def testBmpFile
		if bitsPerPixel < 24
			raise SteganographicError.new("Destination file must be at least a 24 bit BMP.")
		end
		
		# Can't store a file if there is one already stored. We can tell by a 1 stored in the
		# reserve value at the beginning of the file.
		if reserved > 0
			raise SteganographicError.new("Destination file already contains data; remove it first.")
		end
		
		# compression currently not supported.
		if getCompression == "BI_RLE4" || getCompression == "BI_RLE8"
			raise SteganographicError.new("Can't (currently) store data in a compressed BMP.")
		end
	end
end

end # module