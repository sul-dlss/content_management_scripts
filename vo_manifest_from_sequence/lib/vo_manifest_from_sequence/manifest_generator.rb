require 'csv'
require 'roo'
require_relative 'manifest_sheet'

class ManifestGenerator

  attr_reader :filename

  # Creates a new ManifestGenerator
  # @param [String]  filename    The filename of the input spreadsheet.
  def initialize(filename)
    @filename = filename
  end

  def generate_manifest
    # Create new ManifestSheet object (using Roo) from input file
    infile = ManifestSheet.new(@filename)
    # Validate incoming data and return validated spreadsheet object
    sheet = infile.validate
    # Hash to store output data for manifest
    data = Hash.new

    # Populate output data hash:
    # key = parent druid (sequence = 0),
    # value = array of child druids (sequence = 1-N)
    # Assumes that incoming data has passed validation
    sheet.each(sequence: 'sequence', druid: 'druid') do |row|
      if row[:druid] == 'druid'
        next
      end
      if row[:sequence] == 0 || row[:sequence] == '0'
        @current_parent = row[:druid]
        data[@current_parent] = [row[:druid]]
      else
        data[@current_parent] << row[:druid]
      end
    end
    # Reports number of child objects assigned to each parent in the manifest
    puts "parent druid\tchild object count"
    data.each {|parent, children| puts "#{parent}\t#{children.count}"}
    puts "\n"

    # Generate output filename from input filename
    outfile = File.absolute_path(@filename).sub(/\.[A-Za-z]+$/, '_manifest.csv')

    # Write data to manifest CSV file
    # First column contains parent druid
    # Subsequent columns contain child druids in sequence order
    CSV.open(outfile, "wb") do |csv|
      data.each_value do |druids|
        csv << druids
      end
    end
  end

end
