require 'nokogiri'

class MODSFile

  attr_reader :filename, :template

  # @option options [String] :template_file    The full path to the desired template file (a spreadsheet).
  def initialize(filename, template)
    @filename = filename
    @mods = Nokogiri::XML(File.open(File.join(indir, f)))
    @template = template
  end

  def process_mods_file(mods_filename)
    return {'ti1:title' => 'title placeholder'}
  end
end
