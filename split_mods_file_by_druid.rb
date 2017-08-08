require 'nokogiri'

# Usage: ruby split_mods_file_by_druid.rb input_file.xml output_dir
# Reverse of compile_wrap_descMD.rb
# Input file is compiled MODS XML file with xmlDocs/xmlDoc wrapper
# Output files are written to output_dir with filename [druid].xml

input_file = ARGV[0]
output_dir = ARGV[1]

xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>'

doc = Nokogiri(File.open("#{ARGV[0]}"))

records = doc.xpath('//mods')

records.each do |mods|
  druid = mods.parent['objectid']
  outfile = File.open(File.join("#{ARGV[1]}", "#{druid}.xml"), 'w')
  outfile.write("#{xml_declaration}\n")
  outfile.write(mods.to_s)
  outfile.close
end
