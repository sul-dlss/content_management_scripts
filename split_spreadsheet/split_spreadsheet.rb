require 'roo'

infile = ARGV[0]
outdir = ARGV[1]

if ARGV[0] == 'help'
  puts 'Usage: ruby split_spreadsheet.rb path/to/inputfile.xlsx path/to/outputdirectory'
  puts 'Requires "roo" gem for spreadsheet parsing. Use "gem install roo" to install.'
  puts 'Default split size is 1000 lines. Use -n [number] after the output directory to set a different size.'
  puts 'For example, "ruby split_spreadsheet.rb path/to/inputfile.xlsx path/to/outputdirectory -n 500" will produce output files of 500 lines each.'
  exit
end

# Set split size
lines_per_file = 1000
if ARGV.size > 2 && ARGV[2] == '-n'
  lines_per_file = ARGV[3].to_i
end

# Directory for output files
unless Dir.exist?("#{outdir}")
  Dir.mkdir("#{outdir}")
end

# Get filename base for output files
filename_base = File.basename("#{infile}", ".*")

# Open input file as roo XLSX object
input = Roo::Excelx.new("#{infile}")

# Find header row
header_row_index = 1
headers = []
while header_row_index <= 10
  if input.excelx_value(header_row_index,'A').downcase.strip == 'druid'
    input.row(header_row_index).each { |x| headers << x}
    break
  else
    header_row_index += 1
  end
end

# Exit if no header row found
if headers == []
  puts 'Could not find header in first 10 rows'
  exit
end

# Set counters
last_row_index = input.last_row # end of input
file_index = 1 # for filename
start_row_index = header_row_index # where to start each file
row_max = lines_per_file - 1 # max_rows adds 1

# A different segment of the input file is streamed each iteration of the loop,
# so when to stop = when the starting point after the previous iteration is
# beyond the last line of the input file
while start_row_index < last_row_index
  # Open output file
  output_filename = File.join("#{outdir}", "#{filename_base}_#{file_index}.csv")
  output_file = CSV.open("#{output_filename}", 'wb')
  # Write headers from input to output file
  output_file << headers
  # Set line count tracker for reporting
  line_count = 0
  # Stream the portion of the file from the starting point up to the declared
  # number of rows per file
  input.each_row_streaming(pad_cells: true, offset: start_row_index, max_rows: row_max) do |row|
    row_out = []
    # Add values of Excelx::Cell objects to array, replacing empty Excelx::Cell objects with nil
    row.each do |field|
      if field == nil || field == Roo::Excelx::Cell::Empty
        row_out << nil
      else
        row_out << field.value
      end
    end # End of row input
    # Skip output if input row is empty
    next if row_out.compact.empty?
    # Write row to output file
    output_file << row_out
    # Increment output line count
    line_count += 1
  end # End of output file
  # Increment the indexes to set the starting point for the next iteration
  start_row_index += lines_per_file
  file_index += 1
  output_file.close
  # Report output
  puts "#{line_count} lines written to #{output_filename}"
end # End of input file
