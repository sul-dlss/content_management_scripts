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
      'titleInfo',
      'name',
      'typeOfResource',
      'genre',
      'note',
      'abstract',
      'tableOfContents',
      'identifer',
      'recordInfo'
    ]

    @wrapper_elements = [
      'titleInfo',
      'name',
      'role',
      'recordInfo'
    ]

  end

  def process_mods_file
    @basic_elements.each do |element|
      mods_element_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:#{element}")
      template_element_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:#{element}")
      mods_element_nodes.each_with_index do |n, i|
        @column_hash.merge!(extract_attributes(n, template_element_nodes[i]))
        if @wrapper_elements.include?(element)
          @column_hash.merge!(extract_child_attributes_and_values(n, template_element_nodes[i]))
        else
          @column_hash.merge!(extract_self_value(n, template_element_nodes[i]))
        end
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

  def extract_child_attributes_and_values(mods_node, template_node)
    child_attributes_and_values = {}
    child_element_names = get_child_element_names(mods_node)
    child_element_names.each do |name|
      child_mods_nodes = mods_node.xpath("xmlns:#{name}")
      child_template_nodes = template_node.xpath("xmlns:#{name}")
      child_mods_nodes.each_with_index do |n, i|
        child_attributes_and_values.merge!(extract_attributes(n, child_template_nodes[i]))
        child_attributes_and_values.merge!(extract_self_value(n, child_template_nodes[i]))
        # if @paired_code_text_elements.keys.include?(name)
        #   child_attributes_and_values.merge!(extract_code_text_values_and_attributes(n, child_template_nodes[i]))
        # elsif @wrapper_elements.include?(name)
        #   child_attributes_and_values.merge!(extract_child_attributes_and_values(n, child_template_nodes[i]))
        # end
      end
    end
    return child_attributes_and_values
  end

  def extract_self_value(mods_node, template_node)
    self_value = {}
    return {} if mods_node == nil || template_node == nil || mods_node.name == 'text' || @wrapper_elements.include?(mods_node.name)
    header_code = template_node.content.strip
    if header_code.start_with?('[[')
      self_value[header_code.slice(2..-3)] = mods_node.content
    end
    return self_value
  end

  def get_child_element_names(mods_node)
    return [] if mods_node == nil
    child_element_names = mods_node.children.map {|x| x.name}.uniq.reject {|y| y == 'text'}.compact
    return child_element_names
  end

end
