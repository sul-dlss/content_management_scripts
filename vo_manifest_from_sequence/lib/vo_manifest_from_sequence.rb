require 'csv'
require 'roo'
require_relative 'vo_manifest_from_sequence/manifest_sheet'
require_relative 'vo_manifest_from_sequence/manifest_generator'

## Generates manifest used to construct virtual object relationships in Argo
#
# Takes input file with column headers:
# - 'root' (object identifier, same for parent and children)
# - 'sequence' (numeric order of objects, with parent as 0)
# - 'druid' (object druids)
# The order of columns or the presence of additional columns does not matter.
# Input file should be .xlsx, .xls, or .csv
# Usage:
# - ruby vo_manifest_from_sequence.rb /path/to/inputfile
# CSV output file written to input file directory with filename:
# inputfile_manifest.csv

# Record process start time
puts "\nStart: #{Time.now}\n\n"

# Get filename from command line argument
filename = ARGV[0]

# Validate input file data content
# Generate manifest and write to output file in same directory as input
ManifestGenerator.new(filename).generate_manifest

# Record process end time
puts "\nEnd: #{Time.now}\n\n"
