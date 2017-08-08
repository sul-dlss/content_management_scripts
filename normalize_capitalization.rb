# Capitalizes each word in a document (originally developed to process names from export
# data with variable capitalization)
# Usage: ruby normalize_capitalization.rb inputfile.txt outputfile.txt
# Also normalizes to single space between words on line

infile = ARGV[0]
outfile = File.open(ARGV[1], 'w')

File.foreach(infile) do |line|
  next if line.match(/^\s+$/)
  cap_name = []
  words = line.strip.split
  words.each {|word| cap_name << word.capitalize}
  outfile.write(cap_name.join(' ') + "\n")
end

outfile.close
