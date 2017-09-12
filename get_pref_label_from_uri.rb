# Queries a URI plus .nt extension and parses out the prefLabel value from the
# n-triples returned.
# Usage: ruby get_pref_label_from_uri.rb input_file.txt output_file.txt
# Input file should contain the term in the first column and the URI in the
# second column.
# Output file will contain the term from the input file, the term returned from
# the URI, and the URI itself.
# Tested with LCNAF URIs.

infile = ARGV[0]
outfile = File.open("#{ARGV[1]}", 'w')

# Write headers to output file
outfile.write(['Source term', 'Preferred label', 'URI'].join("\t") + "\n")

# Process input file
File.foreach("#{infile}") do |line|
  fields = line.strip.split("\t")
  # bash to query URI plus .nt extension and find prefLabel
  uri_match = `curl -sS "#{fields[1]}.nt" | grep "prefLabel"`
  # Extract label value from prefLabel match
  label_match = uri_match.match(/"([^"]*)"/)
  # If no match (URI does not return results, unable to identify prefLabel),
  # log to output file
  if label_match == nil
    outfile.write([fields[0], 'NOT FOUND', fields[1]].join("\t") + "\n")
    next
  end
  # If match, write to output file
  label = label_match[1]
  outfile.write([fields[0], label, fields[1]].join("\t") + "\n")
end
