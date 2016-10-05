require 'csv'
require 'roo'
require_relative 'manifest_sheet'

# Generates virtual object manifest based on validated spreadsheet input
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
    data = generate_data_hash(sheet)
    report_output_stats(data)
    write_output_file(data)
  end

  def generate_data_hash(sheet)
    # Hash to store output data for manifest
    @data = {}
    # Populate output data hash:
    # key = parent druid (sequence = 0),
    # value = array of child druids (sequence = 1-N)
    # Assumes that incoming data has passed validation
    sheet.each(sequence: 'sequence', druid: 'druid') do |row|
      next if row[:druid] == 'druid'
      populate_data_hash(row)
    end
    @data
  end

  def populate_data_hash(row)
    # Add druid prefix if not present
    druid = check_druid_prefix(row[:druid])
    # Set parent druid if sequence = 0
    if row[:sequence] == 0 || row[:sequence] == '0'
      @current_parent = row[:druid]
      # If child belongs to new parent, add parent key to hash and initialize value array with first child
      @data[@current_parent] = [druid]
    else
      # If child belongs to existing parent, add to value array
      @data[@current_parent] << druid
    end
  end

  def check_druid_prefix(druid)
    # Return if matches desired pattern
    return druid if druid =~ /^druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/
    # Add prefix if not already present
    return "druid:#{druid}" if druid =~ /^[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/
    # Return and warn if pattern not recognized as druid
    puts "Druid not recognized: #{druid}. Processing as-is and continuing - remediate after completion."
    druid
  end

  def report_output_stats(data)
    # Reports number of child objects assigned to each parent in the manifest
    puts "parent druid\tchild object count"
    data.each { |parent, children| puts "#{parent}\t#{children.count}" }
    puts "\n"
  end

  def write_output_file(data)
    # Generate output filename from input filename
    outfile = File.absolute_path(@filename).sub(/\.[A-Za-z]+$/, '_manifest.csv')

    # Write data to manifest CSV file
    # First column contains parent druid
    # Subsequent columns contain child druids in sequence order
    CSV.open(outfile, 'wb') do |csv|
      data.each_value do |druids|
        csv << druids
      end
    end
  end
end
