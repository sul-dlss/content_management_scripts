# Concatenates tabular data from multiple files matching on druid as key
# Usage: ruby integrate_data_by_druid.rb <file-1.txt> <file-2.txt> <file-n.txt> outputfile.txt

outfilename = ARGV.pop
infiles = ARGV
outfile = File.open("#{outfilename}", 'w')

# Hash of output with druids as keys
data_out = {}
# Headers for output - will be added to based on input data
headers_out = ['druid']
# Counter for fields in current file - to pad out short rows
field_count = 0
# Counter for fields in all files processed thus far - to pad before data for druids
# not in previously processed files
cumulative_field_count = 0

# Process input files
infiles.each do |infile|
  File.foreach("#{infile}") do |line|
    fields = line.strip.split("\t")
    # Consider row as header if first field = 'druid'
    if fields[0] == 'druid'
      # Add current file headers to running list, skipping 'druid'
      headers_out << fields[1..-1]
      # Set field count (not counting druid) for current file
      field_count = fields[1..-1].size
      next
    end
    # Skip if no data after first field
    next if fields[1..-1] == nil
    # Pad out row with empty fields to match header count
    fields << '' while fields[1..-1].size < field_count
    # Add current file data to hash entry for druid
    if data_out.has_key?(fields[0])
      data_out[fields[0]] << fields[1..-1]
    else
      # If druid not in data hash, add druid, add initial padding if any, and add
      # current file data to new entry
      data_out[fields[0]] = Array.new(cumulative_field_count, '') + fields[1..-1]
    end
  end
  # Update cumulative field count
  cumulative_field_count += field_count
end

# Flatten any nested arrays in headers and write to output file
outfile.write(headers_out.flatten.join("\t") + "\n")

# Flatten any nested arrays in data and write to output file
data_out.each do |druid, data|
  outfile.write("#{druid}\t" + data.flatten.join("\t") + "\n")
end

outfile.close
