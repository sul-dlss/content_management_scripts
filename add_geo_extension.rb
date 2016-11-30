# Usage: ruby add_geo_extension.rb datafile.xlsx inputdir outputdir
# Column headers in datafile:
#   druid
#   for bounding box coordinates: bb_west, bb_south, bb_east, bb_north
#   for point coordinates: point_lat, point_long
# Coordinate data should be provided in decimal degrees
# Inputdir contains MODS files (filename is druid:[druid].xml, one record per file)
# Default assumes dc:format = image/jpeg and dc:type = Image

require 'nokogiri'
require 'roo'

# Set DC constants
dc_format = 'image/jpeg'
dc_type = 'Image'

datafile = ARGV[0]
inputdir = ARGV[1]
outputdir = ARGV[2]

# Check for existence of input and output directories
if !Dir.exist?(inputdir)
  puts "#{inputdir} does not exist"
  exit
elsif !Dir.exist?(outputdir)
  Dir.mkdir(outputdir)
end

# Row count from datafile
count_in = 0
count_out = 0

# Open datafile spreadsheet
datasheet = Roo::Excelx.new("#{datafile}")
# Check for valid headers and set datatypes
data_headers = datasheet.row(1)
if !data_headers.include?('druid')
  puts "Datafile does not contain column with header 'druid'"
  exit
elsif data_headers.sort == ['bb_east','bb_north','bb_south','bb_west', 'druid']
  @datatype = 'bounding box'
elsif data_headers.sort == ['druid', 'point_lat', 'point_long']
  @datatype = 'point'
else
  puts "Datafile does not contain correct headers"
  exit
end

# Parse columns according to expected headers for datatype
if @datatype == 'bounding box'
  @rows = datasheet.parse(druid: 'druid', bb_south: 'bb_south', bb_west: 'bb_west', bb_east: 'bb_east', bb_north: 'bb_north')
elsif @datatype == 'point'
  @rows = datasheet.parse(druid: 'druid', point_lat: 'point_lat', point_long: 'point_long')
end

# Check for valid data in datafile
error = FALSE
missing_druids = 0
@rows.each do |row|
  next if row.values.compact == [] || row[:druid] == 'druid'
  if row[:druid] == nil
    missing_druids += 1
    error = TRUE
  elsif row[:druid].to_s.strip.match(/[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/) == nil
    puts "Invalid druid: #{row[:druid]}"
    error = TRUE
  elsif row.values.include?(nil)
    puts "Datafile missing coordinate data for #{row[:druid]}"
    error = TRUE
  elsif row.values[1..-1].join(' ').match(/[^0-9. ]/)
    puts "Datafile contains invalid characters in coordinate data for #{row[:druid]}"
    error = TRUE
  end
end
if missing_druids > 0
  puts "#{missing_druids} row(s) missing druids"
end
if error == TRUE
  puts "Exiting due to errors in datafile"
  exit
end

# Process datafile and insert geodata into MODS
@rows.each do |row|
  next if row.values.compact == [] || row[:druid] == 'druid'
  count_in += 1
  # Check for existence of MODS file corresponding to druid in datafile row
  unless Dir.entries(inputdir).include?("druid:#{row[:druid]}.xml")
    puts "File for #{row[:druid]} does not exist in #{inputdir}"
    next
  end
  count_out += 1
  # Open MODS XML
  doc = Nokogiri::XML(open(File.join(inputdir, "druid:#{row[:druid]}.xml"), "r"))
  # Add RDF namespace to root
  doc.root.add_namespace('rdf', "http://www.w3.org/1999/02/22-rdf-syntax-ns#") unless doc.root.namespaces.include?('rdf')
  # Construct extension element based on DC constants, datatype, and datafile row
  if @datatype == 'bounding box'
    geodata = <<GEO
  <extension displayLabel="geo">
    <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
      <rdf:Description rdf:about="http://www.stanford.edu/#{row[:druid]}">
        <dc:format>#{dc_format}</dc:format>
        <dc:type>#{dc_type}</dc:type>
        <gml:boundedBy>
          <gml:Envelope>
            <gml:lowerCorner>#{row[:bb_west]} #{row[:bb_south]}</gml:lowerCorner>
            <gml:upperCorner>#{row[:bb_east]} #{row[:bb_north]}</gml:upperCorner>
          </gml:Envelope>
        </gml:boundedBy>
      </rdf:Description>
    </rdf:RDF>
  </extension>
GEO
  elsif @datatype == 'point'
    geodata = <<GEO
  <extension displayLabel="geo">
    <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
      <rdf:Description rdf:about="http://www.stanford.edu/#{row[:druid]}">
        <dc:format>#{dc_format}</dc:format>
        <dc:type>#{dc_type}</dc:type>
        <gmd:centerPoint>
          <gml:Point gml:id="ID">
            <gml:pos>#{row[:point_lat]} #{row[:point_long]}</gml:pos>
          </gml:Point>
        </gmd:centerPoint>
      </rdf:Description>
    </rdf:RDF>
  </extension>
GEO
  end
  # Insert extension into MODS
  geonode = Nokogiri::XML.fragment(geodata)
  doc.root << geonode
  # Write new MODS file with extension added
  outfile = File.new(File.join(outputdir, "druid:#{row[:druid]}.xml"), "w")
  outfile.write(doc.to_s)
  outfile.close
end

# Report stats
puts "Druids in: #{count_in}"
puts "Druids out: #{count_out}"
