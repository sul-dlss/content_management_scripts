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
      @template_xml = Nokogiri::XML(File.open(options[:template_file]))
    else
      @template_xml = Nokogiri::XML(File.open('lib/reverse_modsulator/modsulator_template.xml'))
    end

    if options[:namespace]
      @namespace = options[:namespace]
    else
      @namespace = 'xmlns'
    end

    process_directory
  end

  # @param [String] dir         Input directory containing MODS XML files.
  # @param [Hash]   data        Empty hash to hold data output.
  # @param [File]   outfile     File object for output rows.
  def process_directory
    Dir.foreach(@dir) do |f|
      next unless f.match('.xml')
      druid = get_druid_from_filename(f)
      mods_file = MODSFile.new(File.join(@dir, f), @template_xml, @namespace)
      @data[druid] = mods_file.process_mods_file
    end
    write_output(@data, @outfile)
  end

  # @param [String] mods_filename   Name of MODS input file.
  def get_druid_from_filename(mods_filename)
    druid = mods_filename.gsub('druid:','').gsub('.xml','')
    return druid
  end

  # @param [Hash]   data        Processed data output.
  # @param [File]   outfile     File object for output rows.
  def write_output(data, outfile)
    rows = data_to_rows(data)
    rows.each {|row| outfile.write(row.join("\t") + "\n")}
  end

  # @param [Hash]   data        Processed data output.
  def data_to_rows(data)
    rows = []
    headers = get_ordered_headers(data)
    rows << headers
#    puts headers.inspect
    data.each do |druid, column_hash|
#      puts column_hash.inspect
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
    return rows
  end

  ## TODO: real ordering following replayable spreadsheet
  # @param [Hash]   data        Processed data output.
  def get_ordered_headers(data)
    headers = get_headers(data)
    ordered_headers = ['druid', 'sourceId'] + headers
    return ordered_headers
  end

  # @param [Hash]   data        Processed data output.
  def get_headers(data)
    headers = []
    data.each do |druid, column_hash|
      headers << column_hash.keys
    end
    headers_out = headers.flatten.uniq
    return headers_out
  end

end
