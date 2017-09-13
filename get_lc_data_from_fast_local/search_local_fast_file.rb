# Searches local preprocessed copy of FAST Linked Data Format N-Triples file for
# matches to terms provided in a text file. Returned results match LC terms or FAST
# alterante labels.
# Usage: ruby search_local_fast_file.rb termlist_file.txt output_file.txt preprocessed_fast_file.nt
# Output: the search term, one or more matches for the LC authorized form of the term,
# and the id.loc.gov URI for each matched term.

# Read search terms from file
termlist = []
File.foreach("#{ARGV[0]}") do |line|
  termlist << line unless line.strip.empty?
end

# Create file for output
outfile = File.open("#{ARGV[1]}", 'w')

# Set counters
term_count = 0
match_count = 0
no_match_count = 0
output_count = 0

# Iterate through terml ist and search each term
termlist.each do |term|
  output_list = []
  term_count += 1
  term.strip!
  # Preserve original term for output
  term_out = term
  # Search for matches in LC authorized terms
  # Search is case-insensitive and left-anchored
  results = `grep "id.loc.gov" #{ARGV[2]} | grep -i "\\"#{term}" | sed -e "s/\\"//g" -e "s/<http:\\/\\/www.w3.org\\/2000\\/01\\/rdf-schema#label> //" -e "s/[<>]//g" -e "s/ \\.//"`
  # If no LC matches search FAST alternate labels (altLabel property)
  # Search is case-insensitive and left-anchored
  if results.empty?
    # Search for term and return FAST URIs
    fast_uri_results = `grep -i "\\"#{term}" #{ARGV[2]} | grep "altLabel" | grep -oP "^.*?>"`
    fast_uri_list = fast_uri_results.split("\n").uniq
    # Get LC URI corresponding to each FAST URI (schema:sameAs property)
    fast_uri_list.each do |fast_uri|
      lc_uri = `grep "#{fast_uri} <http://schema.org/sameAs> <http://id.loc.gov" #{ARGV[2]} | sed -e "s/.*sameAs> <//" -e "s/>.*//"`
      lc_uri.strip!
      # Get LC term corresponding to each LC URI (rdfs:label property)
      lc_term = `grep "<#{lc_uri}> <http://www.w3.org/2000/01/rdf-schema#label>" #{ARGV[2]} | sed -e "s/\\"//g" -e "s/<http:\\/\\/www.w3.org\\/2000\\/01\\/rdf-schema#label> //" -e "s/[<>]//g" -e "s/ \\.//"`
      results << lc_term
    end
  end
  # Write original term to output if no matches
  if results.empty?
    no_match_count += 1
    outfile.write(term_out + "\n")
    next
  end
  # Write original term, authorized match, and match URI to output file, one
  # match per line
  match_count += 1
  output_list = []
  results.split("\n").each {|line| output_list << line.strip.split(' ', 2).reverse.join("\t")}
  output_count += output_list.count
  output_list.each { |output| outfile.write(term_out + "\t" + output + "\n")}
end

# Report statistics
puts "Terms processed: #{term_count}"
puts "#{match_count} matched, #{no_match_count} unmatched"
puts "#{output_count} entries written to output"
