#####################################
#
# File: BMPStego.rb
#
#####################################


require "Stego"

if ARGV.length == 2 
	stego = Bmp::Stego.new(ARGV[0], ARGV[1], nil)
	puts "done"
elsif ARGV.length == 3
	stego = Bmp::Stego.new(ARGV[0], ARGV[1], ARGV[2])
	puts "done"
else
	$stderr.print "Usage: ruby BmpTest.rb 'password' <file.bmp> [<file.x>]\n"
	$stderr.print "       Passing a password one file and will decode any encoded data.\n"
	$stderr.print "       Passing a password and two files will encode file 2 into the file 1.\n"
	exit
end