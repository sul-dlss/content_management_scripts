# Adds purls to a set of MODS files from a druid list and renames files with druids
# Usage: ruby add_purls_and_rename.rb input_directory output_directory list_of_current_filenames_and_druids.txt
# List of current filenames should be tab-delimited text file with filenames (omitting extensions) in first
# column and druids in second

require 'nokogiri'

input_dir = ARGV[0]
output_dir = ARGV[1]
mapfile = ARGV[2]

mapping = {}

# Create hash from filename/druid mapping
File.foreach("#{mapfile}") do |line|
  fields = line.strip.split("\t")
  # key = source ID, value = druid
  mapping[fields[0]] = fields[1]
end

# Iterate over files in input directory and process
Dir.foreach("#{input_dir}") do |filename|
  # Skip non-XML files
  next unless filename.end_with?('.xml')
  # Get identifier from filename by removing extension
  source_id = filename.split('.')[0]
  # Skip if mapping hash doesn't include identifier
  next unless mapping.has_key?(source_id)
  # Get druid that matches the identifier in the mapping hash
  druid = mapping[source_id]
  # Open existing MODS file in input directory named with identifier
  doc = Nokogiri::XML(File.open(File.join("#{input_dir}", "#{filename}")))
  # Create purl node
  purl = doc.create_element('url')
  purl['usage'] = 'primary display'
  purl.content = "http://purl.stanford.edu/#{source_id}"
  # Add purl node as child of existing location node
  location = doc.at_xpath("//xmlns:location")
  location.add_child(purl)
  # Write updated MODS to output directory with druid filename
  outfile = File.open(File.join("#{output_dir}", "druid:#{druid}.xml"), 'w')
  outfile.write(doc.to_s)
  outfile.close
end
