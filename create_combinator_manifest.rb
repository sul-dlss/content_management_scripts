# Generates combinator manifest based on UA Maps project workflow.
# Usage: ruby create_combinator_manifest.rb input_file.txt output_file.txt
# Input file must contain the following in the order given:
## Column 1: druid without "druid:" prefix
## Column 2: parent or child (any other values will be ignored)
# Child objects must appear after their parent in the order they should
# appear in the virtual object.

infile = ARGV[0]
outfile = File.open("#{ARGV[1]}", 'w')

# All data for output
data = []
# Data for a parent its children (one row in manifest)
object = []

# Process input file
File.foreach("#{infile}") do |line|
  fields = line.strip.split("\t")
  # Skip header row
  next if fields[0] == 'druid'
  # If parent, add row for previous object to data for output
  if fields[1] == 'parent'
    data << object if object.size > 0
    # Start new row array for current object
    object = ["druid:#{fields[0]}"]
    # Add child data to row for current parent
  elsif fields[1] == 'child'
    object << "druid:#{fields[0]}"
  end
end

# Add last object row to data for output
data << object if object.size > 0

# Write rows to output file
data.each do |row|
  outfile.write(row.join("\t") + "\n")
end
