# Version of add_geo_extension.rb for when supplied bounding box coordinates are formatted as MARC 035 subfields.
# Usage: ruby add_geo_extension_marc.rb file_with_coordinates.txt input_dir/ output_dir/
# File with coordinates should be tab-delimited text with purl in first column and coordinate data in second
# Input dir should contain MODS files named with druids including the "druid:" prefix

require 'nokogiri'

datafile = File.open("#{ARGV[0]}", "r")
inputdir = ARGV[1]
outputdir = ARGV[2]

# Create output directory if does not already exist
if !Dir.exist?(inputdir)
  puts "#{inputdir} does not exist"
  exit
elsif !Dir.exist?(outputdir)
  Dir.mkdir(outputdir)
end

count_in = 0
count_out = 0

# Process coordinate data and add to MODS
File.foreach(datafile) do |line|
  count_in += 1
  fields = line.strip.split("\t")
  # Get druid from purl
  purl = fields[0]
  druid = fields[0].split("/").last
  # Warn and proceed if no coordinates provided for druid
  if fields[1].nil?
    puts "No coordinates for #{druid}"
    next
  end
  # Split MARC data by subfield
  subfields = fields[1].split(/\s*ǂ/).compact
  # Create hash where key => subfield code, value => coordinates
  coordinates = Hash.new
  subfields.each do |s|
    pair = s.strip.split("\s")
    coordinates[pair[0]] = pair[1] if !pair[0].nil? && !pair[1].nil?
  end
  # Validate coordinate data
  test = coordinates.keep_if { |k,v| k.match(/^[defg]$/) && v.match(/^[0-9]+\.[0-9]+$/) }
  if coordinates.length != 4 || coordinates != test
    puts "Bad coordinate data for #{druid}"
  # Warn and proceed if no MODS file in input directory matches druid
  elsif !Dir.entries(inputdir).include?("druid:#{druid}.xml")
    puts "File for #{druid} does not exist in #{inputdir}"
  else
    # Generate geo extension
    count_out += 1
    doc = Nokogiri::XML(open(File.join(inputdir, "druid:#{druid}.xml"), "r"))
    doc.root.add_namespace('rdf', "http://www.w3.org/1999/02/22-rdf-syntax-ns#") unless doc.root.namespaces.include?('rdf')
    geodata = <<GEO
  <extension displayLabel="geo">
    <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
      <rdf:Description rdf:about="#{purl}">
        <dc:format>image/jpeg</dc:format>
        <dc:type>Image</dc:type>
        <gml:boundedBy>
          <gml:Envelope>
            <gml:lowerCorner>#{coordinates["d"]} #{coordinates["g"]}</gml:lowerCorner>
            <gml:upperCorner>#{coordinates["e"]} #{coordinates["f"]}</gml:upperCorner>
          </gml:Envelope>
        </gml:boundedBy>
      </rdf:Description>
    </rdf:RDF>
  </extension>
GEO
    # Add extension to MODS and write record to output directory
    geonode = Nokogiri::XML.fragment(geodata)
    doc.root << geonode
    outfile = File.new(File.join(outputdir, "druid:#{druid}.xml"), "w")
    outfile.write(doc.to_s)
    outfile.close
  end
end

puts "Druids in: #{count_in}"
puts "Druids out:#{count_out}"

datafile.close
