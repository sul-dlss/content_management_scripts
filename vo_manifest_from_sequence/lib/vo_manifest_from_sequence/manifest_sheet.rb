require 'roo'
require 'roo-xls'

class ManifestSheet

# Methods for processing and validating input file

  attr_reader :filename

  # Creates a new ManifestSheet
  # @param [String]  filename    The filename of the input spreadsheet.
  def initialize(filename)
    @filename = filename
  end

  # Opens a spreadsheet based on its filename extension.
  #
  # @return [Roo::CSV, Roo::Excel, Roo::Excelx]   A Roo object, whose type depends on the extension of the given filename.
  def spreadsheet
    @spreadsheet ||= case File.extname(@filename)
                  when '.csv' then Roo::Spreadsheet.open(@filename, extension: :csv)
                  when '.xls' then Roo::Spreadsheet.open(@filename, extension: :xls)
                  when '.xlsx' then Roo::Spreadsheet.open(@filename, extension: :xlsx)
                  else fail "\n\n***Unknown file type: #{@filename} (must be .csv, .xls, or .xlsx)***\n\n"
    end
  end

  # Confirms that input file follows expected pattern
  # @return spreadsheet A spreadsheet object for the filename argument that passes validation tests
  def validate

    puts "Validating input file #{@filename}...\n\n"
    # Generates sheet object
    @sheet = self.spreadsheet

    # Checks that header contains sequence, root, and druid
    if !@sheet.row(1).include?('sequence') || !@sheet.row(1).include?('root') || !@sheet.row(1).include?('druid')
      puts "Validation failed!!\n\n"
      fail "\n\n***Header error: #{@filename} must contain 'sequence', 'root', and 'druid' in first row***\n\n"
    end
    @rows = @sheet.parse(sequence: 'sequence', root: 'root', druid: 'druid').drop(1)

    root_sequence = {}
    @rows.each do |row|
      # begin block to handle ArgumentError for integer test
      begin
      # Checks for empty cells
      if row.values.compact.count != row.values.count || row.values.count < 3
        puts "Validation failed!!\n\n"
        fail "\n\n***Data error: missing value in #{row}***\n\n"
      elsif root_sequence.has_key?(row[:root])
        root_sequence[row[:root]] << Integer(row[:sequence])
      else
        root_sequence[row[:root]] = [Integer(row[:sequence])]
      end
      # Handles error if row[:sequence] cannot be converted to integer
      rescue ArgumentError
        puts "Validation failed!!\n\n"
        fail "\n\n***Data error: sequence value cannot be converted to integer in #{row}***\n\n"
      end
    end
    root_sequence.each do |r, s|
      # Checks that each root has ordered sequence starting with 0
      if s[0] != 0
        puts "Validation failed!!\n\n"
        fail "\n\n***Data error: root #{r} missing parent numbered 0***\n\n"
      else
        # Checks that sequence values are in numeric order
        while s.count >= 2
          if s.pop != s.last + 1
            puts "Validation failed!!\n\n"
            fail "\n\n***Data error: root #{r} has disordered elements near #{s.last}***\n\n"
          end
        end
      end
    end
    # If no errors, returns sheet object
    puts "Validation successful\n\n"
    return @sheet
  end

end
