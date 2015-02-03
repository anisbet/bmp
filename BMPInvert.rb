#####################################
#
# File: BMPInvert.rb
#
#####################################


require "Bmp"

if ARGV.length == 1 
	bmp = Bmp::BmpFile.new(ARGV[0])
	#puts "xoring: " + bmp.name
	#bmp.xor
	puts "name: " + bmp.name
	puts "compression size: " + bmp.getCompression
	puts "bitmapDataOffset: " + bmp.bitmapDataOffset.to_s
	puts "data size: " + bmp.bitmapDataSize.to_s
	
else
	$stderr.print "Usage: ruby BMPInvert.rb <file.bmp> \n"
	$stderr.print "       Inverts the pixel values of the argument BMP.\n"
	exit
end