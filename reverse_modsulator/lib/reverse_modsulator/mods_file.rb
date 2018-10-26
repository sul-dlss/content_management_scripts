require 'nokogiri'
require 'reverse_modsulator'

class MODSFile

  attr_reader :mods, :template, :ns

  def initialize(filename, template, namespace)
    @mods = Nokogiri::XML(File.open(filename))
    @template = template
    @ns = namespace
  end

  def process_mods_file
    return {'ti1:title' => 'title placeholder'}
  end
end
