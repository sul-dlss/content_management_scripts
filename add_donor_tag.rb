# Spotlight workaround to use the otherwise unused "Donor tags" field as a specialized facet
# Usage: ruby add_donor_tag.rb input_dir/ output_dir/ mapfile.txt
## input_dir contains MODS files with "druid:" prefix in filename
## mapfile.txt is two tab-delimited columns: first column is druid, second column is term to add

require 'nokogiri'

input_dir = ARGV[0]
output_dir = ARGV[1]
mapfile = ARGV[2]

# Create output directory if not existing
unless Dir.exist?("#{output_dir}")
  Dir.mkdir("#{output_dir}")
end

# Create hash for druids and new terms
mapping = {}

File.foreach("#{mapfile}") do |line|
  fields = line.strip.split("\t")
  mapping[fields[0]] = fields[1]
end

# Iterate through druid-term hash and open MODS file with druid in filename
mapping.each do |druid, note|
  # Skip if no term given for druid in mapping
  next if note == ""
  # Open input MODS file
  # NOTE: will fail if there is a druid in the mapping that doesn't have a corresponding file
  doc = Nokogiri::XML(File.open(File.join("#{input_dir}", "druid:#{druid}.xml")))
  # Create donor tags note node
  note_node = doc.create_element("note")
  note_node["displayLabel"] = "Donor tags"
  # Set value as term from mapping
  note_node.content = "#{note}"
  # Add note before first subject node
  # NOTE: will fail if MODS record does not have any subject nodes
  subject = doc.at_xpath("//xmlns:subject")
  subject.previous = note_node
  # Open file in output directory with same filename and write updated MODS record
  outfile = File.open(File.join("#{output_dir}", "druid:#{druid}.xml"), 'w')
  outfile.write(doc.to_s)
end
