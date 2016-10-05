require 'roo'
require 'roo-xls'

# Methods for processing and validating input file
class ManifestSheet
  attr_reader :filename

  # Creates a new ManifestSheet
  # @param [String]  filename    The filename of the input spreadsheet.
  def initialize(filename)
    @filename = filename
  end

  # Opens a spreadsheet based on its filename extension.
  #
  # @return [Roo::CSV, Roo::Excel, Roo::Excelx]   A Roo object, whose type
  #                                                depends on the extension of the given filename.
  def spreadsheet
    @spreadsheet ||= case File.extname(@filename)
                     when '.csv' then Roo::Spreadsheet.open(@filename, extension: :csv)
                     when '.xls' then Roo::Spreadsheet.open(@filename, extension: :xls)
                     when '.xlsx' then Roo::Spreadsheet.open(@filename, extension: :xlsx)
                     else raise "\n\n***Unknown file type: #{@filename} (must be .csv, .xls, or .xlsx)***\n\n"
                     end
  end

  # Confirms that input file follows expected pattern
  # @return spreadsheet A spreadsheet object for the filename argument that passes validation tests
  def validate
    puts "Validating input file #{@filename}...\n\n"
    # Generates sheet object
    @sheet = spreadsheet
    # Check that all required headers are present
    validate_header
    # Parse data columns based on headers
    @rows = @sheet.parse(sequence: 'sequence', root: 'root', druid: 'druid').drop(1)
    # Hash
    @root_sequence = {}
    # Array to hold errors
    @errors = []
    check_empty_and_integer
    check_sequence
    # If no errors, returns sheet object
    puts "Validation successful\n\n"
    @sheet
  end

  def validate_header
    # Checks that header contains sequence, root, and druid
    if !@sheet.row(1).include?('sequence') || !@sheet.row(1).include?('root') || !@sheet.row(1).include?('druid')
      puts '***Validation failed due to header error!! Input data must contain '\
           '"sequence", "root", and "druid" in first row\n\n'
      raise
    end
  end

  def check_empty_and_integer
    @rows.each do |row|
      # begin block to handle ArgumentError for integer test
      begin
        # Checks for empty cells
        if row.values.compact.count != row.values.count || row.values.count < 3
          @errors << "Missing value in #{row}"
        elsif @root_sequence.key?(row[:root].to_s)
          @root_sequence[row[:root].to_s] << Integer(row[:sequence])
        else
          @root_sequence[row[:root].to_s] = [Integer(row[:sequence])]
        end
        # Handles error if row[:sequence] cannot be converted to integer
      rescue ArgumentError
        @errors << "Sequence value cannot be converted to integer in #{row}"
      end
    end
    # If validation fails, writes errors to file and exits
    check_for_errors
  end

  def check_sequence
    @root_sequence.each do |r, s|
      if s[0] != 0
        @errors << "Root #{r} missing parent numbered 0"
      else
        # Checks that sequence values are in numeric order
        while s.count >= 2
          if s.pop != s.last + 1
            @errors << "Root #{r} has disordered elements near #{s.last}"
          end
        end
      end
    end
    # If validation fails, writes errors to file and exits
    check_for_errors
  end

  def check_for_errors
    return if @errors.empty?
    write_error_output
    raise
  end

  def write_error_output
    # Writes errors to file and exits
    unless @errors.empty?
      error_filename = File.absolute_path(@filename).sub(/\.[A-Za-z]+$/, '_errors.txt')
      error_file = File.new(error_filename, 'w')
      @errors.uniq!
      @errors.each { |e| error_file.write("#{e}\n") }
      puts "***Validation failed with #{@errors.count} error(s)!! For details, see:"
      puts "#{error_filename}\n\n"
      raise
    end
  end

end
