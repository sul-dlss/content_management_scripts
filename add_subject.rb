# Adds topic subject node to MODS records from list. One subject added per record.
# Usage: ruby add_subject.rb input_dir/ output_dir/ list_of_druids_and_subjects.txt
# input_dir/ contains MODS files
# List of subjects is tab-delimited text file with druid in first column and subject term in second

require 'nokogiri'

input_dir = ARGV[0]
output_dir = ARGV[1]
mapfile = ARGV[2]

mapping = {}

# Create hash from mapfile, key => druid, value => subject term
File.foreach("#{mapfile}") do |line|
  fields = line.strip.split("\t")
  mapping[fields[0]] = fields[1]
end

# Process input files based on mapping
mapping.each do |druid, subject|
  # Skip if druid provided without subject term
  next if subject == ""
  # Open MODS file matching druid
  doc = Nokogiri::XML(File.open(File.join("#{input_dir}", "druid:#{druid}.xml")))
  # Create subject/topic node
  subject_node = doc.create_element("subject")
  topic_node = doc.create_element("topic")
  topic_node.content = "#{subject}"
  subject_node.add_child(topic_node)
  # Add new subject node after location node
  location = doc.at_xpath("//xmlns:location")
  location.previous = subject_node
  # Write updated record to output directory
  outfile = File.open(File.join("#{output_dir}", "druid:#{druid}.xml"), 'w')
  outfile.write(doc.to_s)
end
