require 'roo'

# Usage: ruby convert_rs_to_archiveit.rb infile.xlsx outfile.ods
# infile.xlsx should have MODS codes (e.g. ti1:title) in top row, followed by data
# Also creates a .csv output - if automatic conversion causes encoding issues, cut and paste from csv into blank ods sheet
# Requires LibreOffice to be installed for conversion
# LibreOffice must *not* be open for conversion to work

infile = ARGV[0]
outfile = ARGV[1]

# Get filename base for interim csv file
csv_filename = outfile.split('.',2)[0] + '.csv'

# Set fields and order for output
output_order = ['URL', 'Title', 'Creator', 'Type', 'Publisher', 'Subject', 'Format', 'Language', 'Description', 'Collector']

# Create sheet object from replayable spreadsheet
sheet_in = Roo::Excelx.new("#{infile}")
# Create csv file object for output
csv_out = CSV.open("#{csv_filename}", "wb")

# Get replayable spreadsheet headers
headers_in = sheet_in.row(1)

## Get indexes for output fields - these will be used to extract data from each row
# Nonrepeatable fields
title_index = headers_in.index('ti1:title')
publisher_index = headers_in.index('or:publisher')
description_index = headers_in.index('ab:abstract')
type_index = headers_in.index('ty1:typeOfResource')
format_index = headers_in.index('ph1:internetMediaType')

# Name-role pairs
names = headers_in.select {|x| x.to_s.match(/^na\d+:namePart$/) || x.to_s.match(/^ro\d+:roleCode$/)}
name_role_index = []
name_role_index << names.shift(2).map {|x| headers_in.index(x)} while names.size > 0

# Subjects - indexes for multiple parts in array, to be concatenated into strings
subjects = headers_in.select {|x| x.to_s.match(/^sn\d+:p\d:name$/) || x.to_s.match(/^sn\d+:p\d:value$/) || x.to_s.match(/^su\d+:p\d:value$/)}
subject_index = []
# Match on header prefix (su1, su2, etc.)
while subjects.size > 0
  prefix = subjects[0].split(':',2)[0]
  subject_string = []
  while subjects[0] != nil && subjects[0].start_with?(prefix)
    subject_string << subjects.shift
  end
  subject_index << subject_string.map {|x| headers_in.index(x)}
end

# Language terms
languages = headers_in.select {|x| x.to_s.match(/la\d:text/)}
language_each_index = []
languages.each {|x| language_each_index << headers_in.index(x)}

# Array to be populated with row hashes
output_data = []

# Track max number of occurences of repeatable fields, to know number of columns to output
output_data_count = {
  'Creator' => 0,
  'Subject' => 0,
  'Language' => 0,
  'Collector' => 0
}

## Process sheet data row by row
sheet_in.each do |row|
  # Skip header row
  next if row == headers_in
  # Set row hash and populate with values for simple indexes
  row_out = {
    'URL' => '',
    'Title' => row[title_index],
    'Creator' => [],
    'Type' => row[type_index],
    'Publisher' => row[publisher_index],
    'Subject' => [],
    'Format' => row[format_index],
    'Language' => [],
    'Description' => row[description_index],
    'Collector' => []
  }
  # Add all language terms
  language_each_index.each {|x| row_out['Language'] << row[x] unless row[x] == nil}
  # Add names only if role code is for creator or collector - all other roles ignored
  name_role_index.each do |x|
    row_out['Creator'] << row[x[0]] if row[x[1]] == 'cre'
    row_out['Collector'] << row[x[0]] if row[x[1]] == 'col'
  end
  # Get subject parts and concatenate into strings with -- separator
  subject_index.each do |x|
    z = x.map {|y| row[y]}
    z.delete(nil)
    row_out['Subject'] << z.join('--') unless z.empty?
  end
  # Get original site URL from note based on display label value in data
  url_displayLabel_index = row.index('Original site')
  # Match on header prefix from display label
  url_note_prefix = headers_in[url_displayLabel_index].split(':')[0]
  url_note_index = headers_in.index("#{url_note_prefix}:note")
  row_out['URL'] = row[url_note_index]
  # Add row hash to output data array
  output_data << row_out
  # Update max occurrence count for repeatable fields
  output_data_count.keys.each {|key| output_data_count[key] = row_out[key].size if row_out[key].size > output_data_count[key]}
end

# Generate ordered header row for output based on max occurrence count for repeatable fields
headers_out = []
output_order.each do |header|
  if output_data_count.keys.include?(header)
    headers_out.concat(Array.new(output_data_count[header], header))
  else
    headers_out << header
  end
end

# Write header row to csv output
csv_out << headers_out

## Write data to csv output
output_data.each do |row|
  # Array for ordered output to csv
  output_row = []
  output_order.each do |field|
    # Pad repeated elements with empty columns if row has less than maximum
    if output_data_count.keys.include?(field)
      while row[field].size < output_data_count[field]
        row[field] << ''
      end
      # Add values to output row with padding
      output_row.concat(row[field].map {|x| x.to_s})
    else
      # Add unrepeated values to output row
      output_row << row[field].to_s
    end
  end
  # Write output row to csv
  csv_out << output_row
end

# Close csv file
csv_out.close

# Convert csv to ods using LibreOffice command line converter
`soffice --headless --convert-to ods #{csv_filename}`

puts 'Done'
