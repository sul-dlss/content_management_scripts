require 'roo'

# Fills in selected fields for child objects with data from parent in a metadata spreadsheet.
# Usage: ruby generate_fill_formulas.rb metadata.xlsx fields_to_exclude.txt

# Get list of headers for fields to not copy from parent
field_list = []
IO.foreach("#{ARGV[1]}") do |line|
  field_list << line.strip
end

# Generate metadata spreadsheet object
metadata_in = Roo::Excelx.new("#{ARGV[0]}")
# Open output file (output will be tab-delimited), filename based on metadata file
outfile_name = File.join(File.dirname("#{ARGV[0]}"), File.basename("#{ARGV[0]}", ".*") + "_out.txt")
outfile = File.open("#{outfile_name}", 'w')

# Indices of columns in skip list
skip_index_list = []
# Index of object type (parent, child, simple) column
object_type_index = ""
# For parent row data, assumes all subsequent child objects belong to that parent until a new
# parent row is identified
row_parent = []

# Iterate through rows in metadata spreadsheet
metadata_in.each do |row|
  # Identify header row - first column has value 'druid'
  if row[0] == 'druid'
    # Populate header array
    headers = []
    row.each do |field|
      if field == nil || field == Roo::Excelx::Cell::Empty
        headers << nil
      else
        headers << field
        # Get indices of columns in input with headers in skip list
        skip_index_list << headers.index(field) if field_list.include?(field)
        # Get index of column in input with object type
        object_type_index = headers.index(field) if field == 'vo:type'
      end
    end
    # Write headers to output file
    outfile.write(headers.join("\t") + "\n")
  # Identify data rows by matching druid pattern in first column
  elsif row[0].match(/[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]\s*/)
    # Output metadata for simple objects as-is
    if row[object_type_index] == 'simple'
      outfile.write(row.join("\t") + "\n")
    # Output metadata for parent objects as-is and store for subsequent children
    elsif row[object_type_index] == 'parent'
      row_parent = row
      outfile.write(row.join("\t") + "\n")
    else
    # Output updated metadata for child objects
      row_out = []
      field_index = 0
      row.each do |field|
        # If in skip list, output as-is
        if skip_index_list.include?(field_index)
          row_out << field
        else
        # Otherwise, output data from parent
          row_out << row_parent[field_index]
        end
        field_index += 1
      end
      # Write to output file
      outfile.write(row_out.join("\t") + "\n")
    end
  end
end
