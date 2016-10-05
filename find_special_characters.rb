require 'nokogiri'

# Identifies lines containing special characters (non-ascii, non-whitespace)
# Usage: ruby find_special_characters.rb /path/to/inputDir /path/to/outputFile

inputDir = ARGV[0]
outputFile = ARGV[1]

outfile = File.new("#{outputFile}", "w")

count = 0

Dir.foreach("#{inputDir}") do |file|
  next if File.directory? file
	infile = File.open(File.join("#{inputDir}", "#{file}"), "r")
  infile.each_line do |line|
# Line below matches combining diacritical and half marks, and bidirectional characters
#    if line.match(/[\u0300-\u036F\u1AB0-\u1AFF\u20D0-\u20FF\u1DC0-\u1DFF\uFE20-\uFE2F\u202A-\u202E\u200E\u200F]/)
# Line below matches all non-ascii, non-whitespace characters
    if line.match(/[^\u0000-\u007F\w]/)
# Line below prints matching character to console
#      line.match(/[^\u0000-\u007F\w]/) {|m| puts m.to_s}
# Line below prints matching character's Unicode code point to console
#      line.match(/[^\u0000-\u007F\w]/) {|m| puts m.to_s.ord.to_s(16)}
      outfile.write("#{file}\t#{line}")
      count += 1
    end
  end
end

puts "Lines changed: #{count}"
