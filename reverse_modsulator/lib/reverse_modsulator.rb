require 'nokogiri'

class ReverseModsulator

  attr_reader :dir, :filename, :template_xml, :namespace

  # @param [String] dir                        Input directory containing MODS XML files.
  # @param [String] filename                   The filename for the output spreadsheet.
  # @param [Hash]   options
  # @option options [String] :template_file    The full path to the desired template file (a spreadsheet).
  # @option options [String] :namespace        The namespace prefix used in the input files.
  def initialize(dir, filename, options = {})
    @dir = dir
    @filename = filename

    @outfile = File.open(@filename, 'w')

    if options[:template_file]
      @template_xml = Nokogiri::XML(File.open(options[:template_file]))
    else
      @template_xml = Nokogiri::XML(File.open(File.expand_path('../reverse_modsulator/modsulator_template.xml', __FILE__)))
    end

    if options[:namespace]
      @namespace = options[:namespace]
    else
      @namespace = 'xmlns'
    end
  end


end
