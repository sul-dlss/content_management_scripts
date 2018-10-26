require 'nokogiri'
require 'reverse_modsulator'

class MODSFile

  attr_reader :mods, :template, :ns

  def initialize(filename, template, namespace)
    @mods = Nokogiri::XML(File.open(filename))
    @template = template
    @ns = namespace

    @column_hash = {}

    @basic_elements = [
      'name'
    ]
  end

  def process_mods_file
    @basic_elements.each do |element|
      mods_element_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:#{element}")
      template_element_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:#{element}")
      mods_element_nodes.each_with_index do |n, i|
        @column_hash.merge!(extract_attributes(n, template_element_nodes[i]))
      end
    end
    return @column_hash
  end

  def extract_attributes(mods_node, template_node)
    return {} if mods_node == nil || template_node == nil
    attributes = {}
    mods_node.each do |attr_name, attr_value|
      header_code = template_node[attr_name]
      next if header_code == nil || !header_code.start_with?('[[')
      attributes[header_code.slice(2..-3)] = attr_value
    end
    return attributes
  end

end
