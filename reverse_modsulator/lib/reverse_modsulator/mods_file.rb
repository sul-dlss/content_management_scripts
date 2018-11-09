require 'nokogiri'
require 'reverse_modsulator'

class MODSFile

  attr_reader :mods, :template, :modified_template, :ns

  # @param [String] filename                Name of MODS file to process.
  # @param [Nokogiri::XML] template         Template as nokogiri document.
  # @param [String] namespace               Namespace used in file for the MODS schema.
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
      'originInfo',
      'language',
      'note',
      'abstract',
      'tableOfContents',
      'identifier',
      'recordInfo'
    ]

    @wrapper_elements = [
      'titleInfo',
      'name',
      'role',
      'originInfo',
      'place',
      'language',
      'relatedItem',
      'recordInfo',
      'languageOfCataloging',
    ]

    @paired_code_text_elements = {
      'role' => ['roleTerm'],
      'language' => ['languageTerm'],
      'place' => ['placeTerm'],
      'languageOfCataloging' => ['languageTerm', 'scriptTerm']
    }

# not included: part, geo extension

  end

  # Match data in MODS input to header codes from template.
  # Related item is separate so the contents of each relatedItem can be processed
  # in the same way as the top-level contents of the mods root.
  # @return [Hash]             Key: header code; value: metadata value.
  def process_mods_file
    @column_hash = process_mods_elements(@mods, @template, "//#{@ns}:mods/")
    @column_hash.merge!(extract_relatedItem)
  end

  # Extract data from MODS element nodes and match with template header codes.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def process_mods_elements(mods, template, xpath_root)
    output = {}
    @basic_elements.each do |element|
      mods_element_nodes = mods.xpath("#{xpath_root}#{@ns}:#{element}")
      template_element_nodes = template.xpath("#{xpath_root}#{@ns}:#{element}")
      mods_element_nodes.each_with_index do |n, i|
        output.merge!(extract_attributes(n, template_element_nodes[i]))
        # TODO: check element type instead of relying on list
        if @wrapper_elements.include?(element)
          output.merge!(extract_child_attributes_and_values(n, template_element_nodes[i]))
        else
          output.merge!(extract_self_value(n, template_element_nodes[i]))
        end
      end
    end
    mods_subject_nodes = mods.xpath("#{xpath_root}#{@ns}:subject")
    template_subject_nodes = template.xpath("#{xpath_root}#{@ns}:subject")
    output.merge!(extract_subjects(mods_subject_nodes, template_subject_nodes))
    # TODO: extract location subelements using this node
    mods_location_node = mods.at_xpath("#{xpath_root}#{@ns}:location")
    output.merge!(extract_repository(mods, template))
    output.merge!(extract_physicalLocation(mods))
    output.merge!(extract_self_value(mods.at_xpath("#{xpath_root}#{@ns}:location/#{@ns}:shelfLocator"), template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:shelfLocator")))
    output.merge!(extract_purl(mods))
    output.merge!(extract_url(mods))
  end

  # Extract attribute values for a given node and match with template header codes.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_attributes(mods_node, template_node)
    return {} if mods_node == nil || template_node == nil
    attributes = {}
    mods_node.each do |attr_name, attr_value|
      header_code = template_node[attr_name]
      next if header_code == nil || !header_code.start_with?('[[')
      attributes[header_code.slice(2..-3)] = attr_value
    end
    attributes
  end

  # Extract attributes and values for the children of a given node and match with
  # template header codes.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_child_attributes_and_values(mods_node, template_node)
    return {} if mods_node == nil || template_node == nil
    child_attributes_and_values = {}
    child_element_names = get_child_element_names(mods_node)
    child_element_names.each do |name|
      child_mods_nodes = mods_node.xpath("#{@ns}:#{name}")
      child_template_nodes = template_node.xpath("#{@ns}:#{name}")
      child_mods_nodes.each_with_index do |n, i|
        child_attributes_and_values.merge!(extract_attributes(n, child_template_nodes[i]))
        # TODO: extract self value only if not paired; check whether this
        # leaves any grandchildren unaccounted for
        child_attributes_and_values.merge!(extract_self_value(n, child_template_nodes[i]))
        if @paired_code_text_elements.keys.include?(name)
           child_attributes_and_values.merge!(extract_code_text_values_and_attributes(n, child_template_nodes[i]))
        # elsif @wrapper_elements.include?(name)
        #   child_attributes_and_values.merge!(extract_child_attributes_and_values(n, child_template_nodes[i]))
        end
      end
    end
    child_attributes_and_values
  end

  # Extract the data value for a given node and match with template header codes.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_self_value(mods_node, template_node)
    self_value = {}
    return {} if mods_node == nil || template_node == nil || mods_node.name == 'text' || @wrapper_elements.include?(mods_node.name)
    header_code = template_node.content.strip
    if header_code.start_with?('[[')
      self_value[header_code.slice(2..-3)] = mods_node.content
    end
    self_value
  end

  # Get list of element names for a the children of a given node.
  # @param [Nokogiri::Node] mods_node       The parent data node to be processed.
  # @return [Array]                         List of child element names (strings).
  def get_child_element_names(mods_node)
    return [] if mods_node == nil
    child_element_names = mods_node.children.map {|x| x.name}.uniq.reject {|y| y == 'text'}.compact
  end

  # Extract the data and attribute values for code/text elemnts that may be paired.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_code_text_values_and_attributes(mods_node, template_node)
    code_text_values = {}
    child_element_names = @paired_code_text_elements[mods_node.name]
    child_element_names.each do |n|
      ['text', 'code'].each do |x|
        header_code = template_node.at_xpath("#{@ns}:#{n}[@type='#{x}']")
        value = mods_node.at_xpath("#{@ns}:#{n}[@type='#{x}']")
        next if header_code == nil || value == nil
        code_text_values[header_code.content.strip.slice(2..-3)] = value.content
        code_text_values.merge!(extract_attributes(value, header_code))
      end
    end
    code_text_values
  end

  # Extract the data and attribute values for all subject elements and match with
  # template header codes.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_subjects(mods_subject_nodes, template_subject_nodes)
    subjects = {}
    mods_subject_name_nodes, template_subject_name_nodes = get_subject_name_nodes(mods_subject_nodes, template_subject_nodes)
    mods_subject_other_nodes, template_subject_other_nodes = get_subject_other_nodes(mods_subject_nodes, template_subject_nodes, mods_subject_name_nodes)
    mods_subject_name_nodes.each_with_index do |sn, i|
      subjects.merge!(extract_subject_values_and_attributes(sn, template_subject_name_nodes[i]))
    end
    mods_subject_other_nodes.each_with_index do |su, i|
      subjects.merge!(extract_subject_values_and_attributes(su, template_subject_other_nodes[i]))
    end
    subjects.merge!(extract_other_geo_subjects(mods_subject_nodes, template_subject_nodes))
  end

  # Select subject elements where any subelement is name and/or titleInfo.
  # @param [Nokogiri::NodeSet] mods_subject_nodes            All subject data nodes.
  # @param [Nokogiri::NodeSet] template_subject_nodes        All subject template nodes.
  # @return [Nokogiri::NodeSet] mods_subject_name_nodes      Subject data nodes with name or titleInfo subelement.
  # @return [Nokogiri::NodeSet] template_subject_name_nodes  Template data nodes with name or titleInfo subelement.
  def get_subject_name_nodes(mods_subject_nodes, template_subject_nodes)
    mods_subject_name_nodes = mods_subject_nodes.xpath("#{@ns}:name|#{@ns}:titleInfo").map {|x| x.parent}.uniq
    template_subject_name_nodes = template_subject_nodes.grep(/sn[\d]+:/)
    return mods_subject_name_nodes, template_subject_name_nodes
  end

  # Select subject elements where subelements are only topic, geographic, temporal, and/or genre.
  # @param [Nokogiri::NodeSet] mods_subject_nodes             All subject data nodes.
  # @param [Nokogiri::NodeSet] template_subject_nodes         All subject template nodes.
  # @param [Nokogiri::NodeSet] mods_subject_name_nodes        Subject data nodes with name or titleInfo subelement.
  # @return [Nokogiri::NodeSet] mods_subject_other_nodes      Subject data nodes with only topic, geographic, temporal, genre subelements.
  # @return [Nokogiri::NodeSet] template_subject_other_nodes  Template data nodes with only topic, geographic, temporal, genre subelements.
  def get_subject_other_nodes(mods_subject_nodes, template_subject_nodes, mods_subject_name_nodes)
    mods_subject_other_nodes = mods_subject_nodes.xpath("#{@ns}:topic|#{@ns}:geographic|#{@ns}:temporal|#{@ns}:genre").map {|x| x.parent}.uniq
    mods_subject_other_nodes.map {|x| mods_subject_other_nodes.delete(x) if mods_subject_name_nodes.include?(x)}
    template_subject_other_nodes = template_subject_nodes.grep(/su[\d]+:/)
    return mods_subject_other_nodes, template_subject_other_nodes
  end

  # Extract data and attribute values from a given subject node and match with
  # template header codes.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_subject_values_and_attributes(mods_node, template_node)
    return {} if mods_node == nil || template_node == nil
    subject_values_and_attributes = {}
    subject_values_and_attributes.merge!(extract_attributes(mods_node, template_node))
    mods_children = mods_node.children.map {|x| x if x.content.match(/\S/)}.compact
    template_children = template_node.children.map {|x| x if x.content.match(/\S/)}.compact
    # skip title template if not in data
    child_subject_types = mods_children.map {|x| x.name}
    if child_subject_types.include?('name') && !child_subject_types.include?('titleInfo')
      template_children.delete(template_children[1])
    end
    mods_children.each_with_index do |s, i|
      subject_values_and_attributes.merge!(extract_subject_child_attributes_and_values(s, template_children[i]))
    end
    subject_values_and_attributes
  end

  # Extract data and attribute values from the children of a given subject node
  # and match with template header codes, except for cartographics and
  # hierarchicalGeographic subelements.
  # @param [Nokogiri::Node] mods_node       The data node to be processed.
  # @param [Nokogiri::Node] template_node   The corresponding template node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_subject_child_attributes_and_values(mods_node, template_node)
    child_attributes_and_values = {}
    return {} if mods_node == nil || template_node == nil
    if ['topic', 'geographic', 'temporal', 'genre'].include?(mods_node.name)
      header_code = template_node.content.match(/s[nu][\d]+:p[\d]:/)[0] + "type"
      child_attributes_and_values.merge!({header_code => mods_node.name})
    elsif ['name', 'titleInfo'].include?(mods_node.name)
      child_attributes_and_values.merge!(extract_child_attributes_and_values(mods_node, template_node)) #handle multiple nameParts
    end
    child_attributes_and_values.merge!(extract_attributes(mods_node, template_node))
    child_attributes_and_values.merge!(extract_self_value(mods_node, template_node))
  end

  # Extract data and attribute values for subjects with cartographics or
  # hierarchicalGeographic subelements and match with template header codes.
  # @param [Nokogiri::NodeSet] mods_subject_nodes           All subject data nodes.
  # @param [Nokogiri::NodeSet] template_subject_nodes       All subject template nodes.
  # @return [Hash]                                          Key: header code; value: metadata value.
  def extract_other_geo_subjects(mods_subject_nodes, template_subject_nodes)
    geo_subjects = {}
    ['cartographics', 'hierarchicalGeographic'].each do |gs|
      mods_subject_geo_nodes = mods_subject_nodes.xpath("#{@ns}:#{gs}")
      next if mods_subject_geo_nodes == nil
      template_subject_geo_nodes = template_subject_nodes.xpath("#{@ns}:#{gs}")
      mods_subject_geo_nodes.each_with_index do |c, i|
        geo_subjects.merge!(extract_child_attributes_and_values(c, template_subject_geo_nodes[i]))
      end
    end
    geo_subjects
  end

  # Extract repository value and attributes from first location node.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_repository(mods, template)
    repository = {}
    mods_repository_node = @mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    return {} if mods_repository_node == nil
    template_repository_node = template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    repository_attributes = extract_attributes(mods_repository_node, template_repository_node)
    repository = {'lo:repository' => mods_repository_node.content}.merge!(repository_attributes)
    return repository
  end

  # Extract first non-repository physicalLocation value from first location node
  # and assign header code.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_physicalLocation(mods)
    physicalLocation = {}
    mods_physicalLocation_nodes = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation")
    return {} if mods_physicalLocation_nodes == nil
    mods_physicalLocation_nodes.each do |p|
      physicalLocation.merge!({'lo:physicalLocation' => p.content}) if p['type'] != 'repository'
    end
    return physicalLocation
  end

  # Extract first purl from first location node and assign header code.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_purl(mods)
    purl = {}
    purl = mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url[@usage='primary display']")
    return {} if purl == nil
    return {'lo:purl' => purl.content}
  end

  # Extract URL and displayLabels for non-purls from first location node and
  # assign header codes.
  # If multiple non-purl URLs are present, only the final one is captured.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_url(mods)
    url = {}
    mods_urls = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url")
    mods_urls.each do |u|
      url.merge!({'lo:url' => u.content}) if u['usage'] != 'primary display'
      url.merge!({'lo:url:displayLabel' => u['displayLabel']}) if u['displayLabel'] != nil
    end
    url
  end

  # Extract relatedItem data and attribute values, and match with template header codes.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_relatedItem
    relatedItems = {}
    mods_relatedItem_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    return {} if mods_relatedItem_nodes == nil
    template_relatedItem_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    mods_relatedItem_nodes.each_with_index do |ri, i|
      next if ri.at_xpath(".//#{@ns}:typeOfResource")['collection'] == "yes"
      relatedItems.merge!(extract_attributes(ri, template_relatedItem_nodes[i]))
      relatedItems.merge!(process_mods_elements(ri, template_relatedItem_nodes[i], "./"))
    end
    relatedItems
  end

end
