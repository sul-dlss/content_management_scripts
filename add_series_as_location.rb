require 'nokogiri'

# Workaround to hack the metadata so that archival series is indexed to Series facet in
# current Spotlight configuration.
# Usage: ruby add_series_as_location.rb input_dir/ output_dir/
# Input directory contains MODS files that have archival series where it is supposed to be:
#   <relatedItem type="host" displayLabel="series"><titleInfo><title>
# Script copies that to:
#   <location> # existing Node
#      <physicalLocation type="series">
# Script also corrects capitalization of relatedItem displayLabel to the expected "Series"
# if needed.

input_dir = Dir.new(ARGV[0])
output_dir = ARGV[1]

# Create output directory if not existing
unless Dir.exist?("#{output_dir}")
  Dir.mkdir("#{output_dir}")
end

# Counter for records to which series data is added
count = 0

# Iterate over files in input_dir
input_dir.each do |filename|
  # Skip directories
  next if File.directory?(filename)
  # Flag for whether new record is output, default TRUE
  add_phys_loc = TRUE
  # Open MODS file
  @doc = Nokogiri::XML(open(File.join("#{ARGV[0]}", "#{filename}")))
  # Get existing series data from relatedItem, if available
  # Check for lowercase displayLabel "series" and capitalize in new node for output
  series = @doc.at_xpath('//xmlns:relatedItem[@displayLabel="series"]//xmlns:titleInfo//xmlns:title')
  if series
    series.parent.parent['displayLabel'] = "Series"
    series.parent.parent['type'] = "host"
  else
    # Check for capitalized displayLabel "Series" and generate new node for output
    series = @doc.at_xpath('//xmlns:relatedItem[@displayLabel="Series"]//xmlns:titleInfo//xmlns:title')
    series.parent.parent['type'] = "host"
  end
  # Skip to next if record does not contain series info in expected relatedItem syntax
  # No file output
  if series.nil?
    puts "No series: #{filename}"
    next
  # Check if series info already exists in physicalLocation element; if so, do not add again
  elsif @doc.at_xpath('//xmlns:location//xmlns:physicalLocation[@type="series"]')
    puts "Has series: #{filename}"
    add_phys_loc = FALSE
  end
  # Add series physicalLocation node after existing repository physicalLocation node if updated
  if add_phys_loc
    repository = @doc.at_xpath('//xmlns:location//xmlns:physicalLocation[@type="repository"]')
    new_series_node = Nokogiri::XML::Node.new "physicalLocation", @doc
    # Spotlight indexer matches on this string in the element value to identify series name
    new_series_node.content = "Series: #{series.text}"
    new_series_node["type"] = "series"
    repository.add_next_sibling(new_series_node)
    puts "Series added: #{filename}"
    count += 1
  end
  # Write file to output directory if series added to or already present in physicalLocation
  # Latter is to correct capitalization of relatedItem displayLabel "series" if necessary
  @doc.write_to(File.open(File.join("#{ARGV[1]}", "#{filename}"), "w"))
end

puts "Series as location added to #{count.to_s} records"
