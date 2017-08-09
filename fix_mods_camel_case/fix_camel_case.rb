# Replaces all-lowercase MODS element tags with correctly camel-cased ones.
# Usage: ruby fix_camel_case.rb input_directory output_directory
# Input directory contains MODS files with .xml file extension
# Requires additional file all_mods_elements.txt

dir_in = ARGV[0]
dir_out = ARGV[1]

# Create hash of bad tags and replacements from list of all MODS elements
camel_case_open = {}
camel_case_close = {}
File.foreach("all_mods_elements.txt") do |line|
  camel_case_open["<#{line.strip.downcase}"] = "<#{line.strip}"
  camel_case_close["</#{line.strip.downcase}"] = "</#{line.strip}"
end

count = 0

# Iterate over files in input directory and replace bad data with good
Dir.foreach("#{ARGV[0]}") do |fh|
  next unless fh.end_with?('.xml')
  outfile = File.open(File.join("#{dir_out}", "#{fh}"), 'w')
  File.foreach(File.join("#{dir_in}", "#{fh}")) do |line|
    output = line.gsub(/<[a-z]+/, camel_case_open).gsub(/<\/[a-z]+/, camel_case_close)
    # Write updated file to output directory
    outfile.write(output)
  end
  outfile.close
  count += 1
end

puts count
