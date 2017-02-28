# Usage: ruby process_mapping.rb infile.xlsx outputdirectory mapfile.tsv
# Values in first column of mapfile (target fields for output) must be unique
# Output will be in the same order as the target fields in the mapfile
# No headers in mapfile, tab-separated values
# Columns in mapfile:
#   mapfile:1 = target field
#   mapfile:2 = source field or data strings with or without {variables} (=name of any source field incorporated in string)
#   mapfile:3 = enumerated: map, string, complex (=contains {variables})
#   mapfile:4 = source field dependency (if the source field given in mapfile:4 is empty, don't populate mapfile:1)
# Processes source file sheet by sheet and writes each sheet to a separate file in the output directory using the sheet name as filename
# Output files are tab-separated values

require 'roo'

infile = ARGV[0]
outdir = ARGV[1]
mapfile = ARGV[2]

## Hashes for data from mapfile
# Fields to map directly from source
@mapdata = {}
# Fields to populate with string (no {variables})
@stringdata = {}
# Fields to populate with string containing {variables}
@complexdata = {}
# Fields with dependencies on other fields
@datarules = {}

# Order of target fields in mapfile, to use for output
output_order = []

## Process mapfile
File.foreach("#{mapfile}") do |line|
  fields = line.strip.split("\t")
  # Add target field to output order
  output_order << fields[0]
  # Skip the rest if target field is only value in row (will be blank column under header in output)
  next if fields.size == 1
  # Populate mapping hashes based on value in third column
  @mapdata[fields[0]] = fields[1] if fields[2] == "map"
  @stringdata[fields[0]] = fields[1] if fields[2] == "string"
  @complexdata[fields[0]] = fields[1] if fields[2] == "complex"
  # Check for fourth column value and add dependency rule if present
  @datarules[fields[0]] = fields[3] if fields.size == 4
end

# Create spreadsheet object from infile
sheets_in = Roo::Excelx.new("#{infile}")

## Iterate through sheets in input spreadsheet, processing data in each sheet separately
sheets_in.each_with_pagename do |name, sheet|
  # Output file for sheet has same name as the sheet in the source file
  outfile = File.new(File.join("#{outdir}", "#{name}.txt"), 'w')
  # Write target headers to output
  outfile.write(output_order.join("\t") + "\n")
  # Get source headers for data field indexes
  data_fields = sheet.row(1)
  # Iterate through rows in sheet
  sheet.each do |row|
    # Skip header row
    next if row == data_fields
    # Populate row hash with constant string data from mapfile
    data_out = Hash.new.merge(@stringdata)
    # Add source data to row hash based on simple mapping
    @mapdata.each do |target, source|
      data_out[target] = row[data_fields.index(source)] if data_fields.include?(source)
    end
    # Add source data to row hash incorporating {variables}
    @complexdata.each do |target, source|
      data_out[target] = source.gsub(/{[^}]*}/) {|s| row[data_fields.index(s[1..-2])]}
    end
    # Delete data from row hash when required dependency is not present
    @datarules.each do |target, rule|
      if data_fields.index(rule) == nil || row[data_fields.index(rule)] == nil || row[data_fields.index(rule)] =~ /^\s+$/
        data_out[target] = nil
      end
    end
    # Ordered array for output data
    row_out = []
    ## Write data to output
    output_order.each do |field|
      if data_out[field] != nil
        # Remove newlines and extra spaces from within cell values
        data = data_out[field].gsub(/[\r\n]/," ").gsub(/\s+/," ").strip
        # Add cleaned data to output array
        row_out << data
      else
        # Padding for blank column if data not present
        row_out << ""
      end
    end
    # Write row to output
    outfile.write(row_out.join("\t") + "\n")
  end
  outfile.close
end
