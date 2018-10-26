require 'nokogiri'
require 'reverse_modsulator'

class MODSFile

  attr_reader :mods

  # @option options [String] :template_file    The full path to the desired template file (a spreadsheet).
  def initialize(filename)
    @mods = Nokogiri::XML(File.open(filename))
  end

  def process_mods_file(mods_filename)
    return {'ti1:title' => 'title placeholder'}
  end
end
