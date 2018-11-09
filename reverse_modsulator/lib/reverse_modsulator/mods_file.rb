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

    # Elements that can be processed similarly.
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

    # Elements that have child elements rather than directly containing a value.
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

    # <keys> are elements that may contain a pair of child elements <value> representing
    # the same information as code and text, as specifed in the type attribute.
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
  # Takes mods and template as arguments to support relatedItem processing.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @param [String] xpath_root        The relative XPath context for the elements processed.
  # @return [Hash]                    Key: header code; value: metadata value.
  def process_mods_elements(mods, template, xpath_root)
    output = {}
    @basic_elements.each do |element|
      # Get the nodeset for this element from the MODS file and the corresponding
      # nodeset from the modsulator template for elements following the same pattern.
      mods_element_nodes = mods.xpath("#{xpath_root}#{@ns}:#{element}")
      template_element_nodes = template.xpath("#{xpath_root}#{@ns}:#{element}")
      mods_element_nodes.each_with_index do |n, i|
        # Get element attributes and header codes
        output.merge!(extract_attributes(n, template_element_nodes[i]))
        # Process nested child elements if present
        if n.children.size > 1
          output.merge!(extract_child_attributes_and_values(n, template_element_nodes[i]))
        # Otherwise get the data value of the element
        else
          output.merge!(extract_self_value(n, template_element_nodes[i]))
        end
      end
    end
    # Subjects
    mods_subject_nodes = mods.xpath("#{xpath_root}#{@ns}:subject")
    template_subject_nodes = template.xpath("#{xpath_root}#{@ns}:subject")
    output.merge!(extract_subjects(mods_subject_nodes, template_subject_nodes))
    # Locations
    mods_location_node = mods.at_xpath("#{xpath_root}#{@ns}:location")
    template_location_node = template.at_xpath("#{xpath_root}#{@ns}:location")
    output.merge!(extract_locations(mods_location_node, template_location_node))
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
      # Skip if value hardcoded in template rather than [[header code]]
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
        # TODO: is this recursivity needed?
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

  # Extract the data and attribute values for code/text elements that may be paired.
  # Elements are still processed if only one of the pair is present.
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

  ### subject

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
  # The selcted subject elements may also have topic, geographic, temporal, and/or genre subelements.
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
    # Skip empty-space text nodes
    mods_children = mods_node.children.map {|x| x if x.content.match(/\S/)}.compact
    template_children = template_node.children.map {|x| x if x.content.match(/\S/)}.compact
    # Skip titleInfo in template if not present in data - template uses snX:p2
    # for both titleInfo and topic etc. subject type, throwing off the index matching if the
    # data uses the second p2 pattern and not the first.
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
    # Process these subelements regardless of whether name and/or titleInfo are also present.
    # Type is an element name and has been replaced in the template object with generic
    # value 'topic' so as to not break XPath. The header code prefixes are picked up from
    # elsewhere in the same line of the template to generate the suX:pX:type header.
    if ['topic', 'geographic', 'temporal', 'genre'].include?(mods_node.name)
      header_code = template_node.content.match(/s[nu][\d]+:p[\d]:/)[0] + "type"
      child_attributes_and_values.merge!({header_code => mods_node.name})
    # Name and titleInfo have nested child elements and must be processed separately.
    elsif ['name', 'titleInfo'].include?(mods_node.name)
      child_attributes_and_values.merge!(extract_child_attributes_and_values(mods_node, template_node))
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

  ### location

  # Extract data and attribute values from location subelements and match with
  # template header codes. Processes first location element and first instance of each
  # subelement type only.
  # @param [Nokogiri::Node] mods      Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template  The template node corresponding to the data node.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_locations(mods_location_node, template_location_node)
    return {} if mods_location_node == nil
    locations = {}
    l = [mods_location_node, template_location_node]
    # Repository
    locations.merge!(extract_from_relative_xpath(*l, "./#{@ns}:physicalLocation[@type='repository']"))
    # Other physical location
    locations.merge!(extract_from_relative_xpath(*l, "./#{@ns}:physicalLocation[not(@type) or @type!='repository']"))
    # PURL
    locations.merge!(extract_from_relative_xpath(*l, "./#{@ns}:url[@usage='primary display']"))
    # Other URL
    locations.merge!(extract_from_relative_xpath(*l, "./#{@ns}:url[not(@usage) or @usage!='primary display']"))
    # Shelf locator (call number)
    locations.merge!(extract_from_relative_xpath(*l, "./#{@ns}:shelfLocator"))
  end

  # Extract data and attributes from xpath relative to a given node and match
  # with template header codes. Returns first XPath match only.
  # @param [Nokogiri::Node] mods_node       Nokogiri document or node with data to be processed.
  # @param [Nokogiri::Node] template_node   The template node corresponding to the data node.
  # @return [Hash]                          Key: header code; value: metadata value.
  def extract_from_relative_xpath(mods_node, template_node, xpath)
    values = {}
    mods_xpath_node = mods_node.at_xpath(xpath)
    return {} if mods_xpath_node == nil
    template_xpath_node = template_node.at_xpath(xpath)
    values.merge!(extract_self_value(mods_xpath_node, template_xpath_node))
    values.merge!(extract_attributes(mods_xpath_node, template_xpath_node))
  end

  ### relatedItem

  # Extract relatedItem data and attribute values, and match with template header codes.
  # @return [Hash]                    Key: header code; value: metadata value.
  def extract_relatedItem
    relatedItems = {}
    mods_relatedItem_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    return {} if mods_relatedItem_nodes == nil
    template_relatedItem_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    # Process each relatedItem in same way as top-level document, using XPath
    # relative to relatedItem node
    mods_relatedItem_nodes.each_with_index do |ri, i|
      # Skip if relatedItem is for collection (not in descMetadata, inserted into
      # public MODS XML on PURL)
      next if ri.at_xpath(".//#{@ns}:typeOfResource")['collection'] == "yes"
      relatedItems.merge!(extract_attributes(ri, template_relatedItem_nodes[i]))
      relatedItems.merge!(process_mods_elements(ri, template_relatedItem_nodes[i], "./"))
    end
    relatedItems
  end

end
