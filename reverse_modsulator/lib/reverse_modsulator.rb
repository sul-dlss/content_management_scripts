require 'nokogiri'
require 'reverse_modsulator/mods_file'

class ReverseModsulator

  attr_reader :dir, :filename, :template_xml, :namespace, :data

  # @param [String] dir                        Input directory containing MODS XML files.
  # @param [String] filename                   The filename for the output spreadsheet.
  # @param [Hash]   options
  # @option options [String] :template_file    The full path to the desired template file (a spreadsheet).
  # @option options [String] :namespace        The namespace prefix used in the input files.
  def initialize(dir, filename, options = {})
    @dir = dir
    @filename = filename
    @outfile = File.open(@filename, 'w')
    @data = {}

    if options[:template_file]
      @template_filename = options[:template_file]
    else
      @template_filename = 'lib/reverse_modsulator/modsulator_template.xml'
    end
    if options[:namespace]
      @namespace = options[:namespace]
    else
      @namespace = 'xmlns'
    end

    @template_xml = Nokogiri::XML(modify_template)
    process_directory
  end

  # Replace subject subelements given as header codes with 'topic' for parseable XML.
  # @return [StringIO]          Modified template.
  def modify_template
    template = File.read(@template_filename)
    working_template = template.gsub(/\[\[s[un]\d+:p\d:type\]\]/, 'topic')
    StringIO.new(string=working_template, 'r')
  end

  # Process a directory of single-record MODS files where the filename is the druid.
  # Write output to specified file.
  def process_directory
    Dir.foreach(@dir) do |f|
      next unless f.match('.xml')
      druid = get_druid_from_filename(f)
      mods_file = MODSFile.new(File.join(@dir, f), @template_xml, @namespace)
      @data[druid] = mods_file.process_mods_file
    end
    write_output
  end

  # Get the druid for output from the MODS filename.
  # @param [String] mods_filename   Name of MODS input file.
  def get_druid_from_filename(mods_filename)
    mods_filename.gsub('druid:','').gsub('.xml','')
  end

  # Write tab-delimited output to file.
  # @param [Hash]   data        Processed data output.
  # @param [File]   outfile     File object for output rows.
  def write_output
    rows = data_to_rows
    rows.each {|row| @outfile.write(row.join("\t") + "\n")}
  end

  # Convert processed data hash to array of arrays with header codes as first entry.
  # @return [Array]             Array of row arrays for output.
  def data_to_rows
    rows = []
    headers = get_ordered_headers
    rows << headers
    @data.each do |druid, column_hash|
      row_out = [druid]
      headers.each do |header|
        if header == 'druid'
          next
        elsif column_hash.keys.include?(header)
          row_out << column_hash[header]
        else
          row_out << ""
        end
      end
      rows << row_out
    end
    rows
  end

  # Put data header codes in the order in which they appear in the template.
  # @return [Array]             Ordered list of header codes appearing in the data output.
  def get_ordered_headers
    headers = get_headers
    template_headers = get_template_headers
    ordered_headers = ['druid', 'sourceId']
    template_headers.each {|th| ordered_headers << th if headers.include?(th)}
    ordered_headers
  end

  # Get array of header codes from processed data.
  # @return [Array]             Unordered list of header codes appearing in the data output.
  def get_headers
    headers = []
    @data.each do |druid, column_hash|
      headers << column_hash.keys
    end
    headers_out = headers.flatten.uniq
  end

  # Get ordered array of header codes from the template.
  # @return [Array]             Ordered list of header codes appearing in the template.
  def get_template_headers
    template_headers = File.read(@template_filename).scan(/\[\[([A-Za-z0-9:]+)\]\]/).uniq.flatten
  end

end
