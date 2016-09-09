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
    data = generate_data_hash(sheet)
    report_output_stats(data)
    write_output_file(data)
  end

  def generate_data_hash(sheet)
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
      druid = check_druid_prefix(row[:druid])
      if row[:sequence] == 0 || row[:sequence] == '0'
        @current_parent = row[:druid]
        data[@current_parent] = [druid]
      else
        data[@current_parent] << druid
      end
    end
    return data
  end

  def check_druid_prefix(druid)
    case
    when druid.match(/^druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/)
      return druid
    when druid.match(/^[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/)
      new_druid = "druid:#{druid}"
      return new_druid
    else
      puts "Druid not recognized: #{druid}. Processing as-is and continuing - remediate after completion."
      return druid
    end
  end


  def report_output_stats(data)
    # Reports number of child objects assigned to each parent in the manifest
    puts "parent druid\tchild object count"
    data.each {|parent, children| puts "#{parent}\t#{children.count}"}
    puts "\n"
  end

  def write_output_file(data)
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
