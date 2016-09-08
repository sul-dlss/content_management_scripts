require 'nokogiri'
require 'net/http'

# Sends requests to OCLC FAST API based on search terms in a text file, and
# returns LC authorized forms and identifiers that match the term.
# Raw API response is RDF/XML, processed for tabular output.

# Usage: ruby get_lc_data_from_fast_api.rb infile.txt outfile.xml

# Get input and output filenames from command line
infilename = ARGV[0]
outfilename = ARGV[1]

# Open output file
outfile = File.new("#{outfilename}", 'w')

# Gather stats to write to console at completion
term_count = 0
match_count = 0
no_match_count = 0
result_count = 0
output_count = 0

# Read terms from input file, url-encode, and send GET request to API
File.foreach(infilename) do |term|
  term_count += 1
  term.strip!
  term_encode = URI.encode(term)
  url = URI.parse("http://experimental.worldcat.org/fast/search?query=cql.any%20all%20%22#{term_encode}%22")
  request = Net::HTTP::Get.new(url)
  request["Accept"] = "application/rdf+xml"
  response = Net::HTTP.start(url.hostname, url.port) do |http|
    http.request(request)
  end
  # Process API response and generate output if any
  doc = Nokogiri::XML(response.body)
  # Create nodeset of individual results from response
  result_set = doc.xpath('/rdf:RDF/rdf:Description')
  # If no results returned, write unmatched term to output and continue to next
  if result_set.empty?
    no_match_count += 1
    outfile.write("#{term}\n")
    next
  end
  match_count += 1
  # Iterate over results
  result_set.each do |result|
    # Find the LC URI
    lc = result.xpath('schema:sameAs/rdf:Description[contains(@rdf:about,"id.loc.gov")]')
    # Extract the output text values from the RDF/XML
    # Output: search term, authorized LC term, term type (topical, geographical, etc.), LC URI
    # If a term returns multiple matches, each is written to output on a separate line
    lc.each do |l|
      result_count += 1
      lc_term = l.content.strip
      lc_uri = l['rdf:about'].strip
      type = result.at_xpath('skos:inScheme[contains(@rdf:resource,"facet")]')
      lc_type = type['rdf:resource'].strip.gsub(/ontology\/1.0\/#facet-/, '').downcase
      # Exclude name-title entries and deprecated forms
      unless lc_type == "title" || result.at_xpath('dct:isReplacedBy')
        output_count += 1
        outfile.write("#{term}\t#{lc_term}\t#{lc_type}\t#{lc_uri}\n")
      end
    end
  end
end

# Close output file
outfile.close

# Print stats to console
puts "Terms processed: #{term_count}"
puts "#{match_count} matched, #{no_match_count} unmatched"
puts "#{result_count} matches returned"
puts "#{output_count} entries written to output"
