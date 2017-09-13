# Extracts from FAST n-triples download file only lines needed for identifying
# LC URIs and converts escaped unicode to UTF-8 for string matching
# Usage: ruby preprocess_local_fast_file.rb infile.nt outfile.nt

infile = ARGV[0]
outfile = File.open("#{ARGV[1]}", 'w')

# Get LC labels and FAST/LC sameAs assertions
output_data = `grep "id.loc.gov" #{infile}`.split("\n")
# Get FAST altLabels for improved matching
output_data += `grep "altLabel" #{infile}`.split("\n")

# Replace escaped unicode with UTF-8 characters and write to output file
output_data.each do |line|
  outfile.write(line.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")} + "\n")
end

outfile.close
