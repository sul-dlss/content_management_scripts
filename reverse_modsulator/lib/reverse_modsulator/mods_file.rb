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

# geo extension

  end

  def process_mods_file
    @column_hash = process_mods_elements(@mods, @template, "//#{@ns}:mods/")
    @column_hash.merge!(extract_relatedItem(@mods, @template))
    return @column_hash
  end

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
    mods_location_node = mods.at_xpath("#{xpath_root}#{ns}:location")
    output.merge!(extract_repository(mods, template))
    output.merge!(extract_physicalLocation(mods))
    output.merge!(extract_self_value(mods.at_xpath("#{xpath_root}#{@ns}:location/#{@ns}:shelfLocator"), template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:shelfLocator")))
    output.merge!(extract_purl(mods))
    output.merge!(extract_url(mods))
    return output
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
    return code_text_values
  end

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
    return subjects
  end

  def get_subject_name_nodes(mods_subject_nodes, template_subject_nodes)
    mods_subject_name_nodes = mods_subject_nodes.xpath("#{@ns}:name|#{@ns}:titleInfo").map {|x| x.parent}.uniq
    template_subject_name_nodes = template_subject_nodes.grep(/sn[\d]+:/)
    return mods_subject_name_nodes, template_subject_name_nodes
  end

  def get_subject_other_nodes(mods_subject_nodes, template_subject_nodes, mods_subject_name_nodes)
    mods_subject_other_nodes = mods_subject_nodes
    mods_subject_other_nodes.map {|x| mods_subject_other_nodes.delete(x) if mods_subject_name_nodes.include?(x)}
    template_subject_other_nodes = template_subject_nodes.grep(/su[\d]+:/)
    return mods_subject_other_nodes, template_subject_other_nodes
  end

  def extract_subject_values_and_attributes(mods_node, template_node)
    return {} if mods_node == nil || template_node == nil
    subject_values_and_attributes = {}
    subject_values_and_attributes.merge!(extract_attributes(mods_node, template_node))
    mods_children = mods_node.children.map {|x| x if x.content.match(/\S/)}.compact
    template_children = template_node.children.map {|x| x if x.content.match(/\S/)}.compact
    mods_children.each_with_index do |s, i|
      subject_values_and_attributes.merge!(extract_subject_child_attributes_and_values(s, template_children[i]))
    end
    return subject_values_and_attributes
  end

  def extract_subject_child_attributes_and_values(mods_node, template_node)
    child_attributes_and_values = {}
    return {} if mods_node == nil || template_node == nil
    if ['topic', 'geographic', 'temporal', 'genre'].include?(mods_node.name)
      header_code = template_node.content.match(/s[nu][\d]+:p\d:/)[0] + "type"
      child_attributes_and_values.merge!({header_code => mods_node.name})
    elsif ['name', 'titleInfo'].include?(mods_node.name)
      child_attributes_and_values.merge!(extract_child_attributes_and_values(mods_node, template_node)) #handle multiple nameParts
    end
    child_attributes_and_values.merge!(extract_attributes(mods_node, template_node))
    child_attributes_and_values.merge!(extract_self_value(mods_node, template_node))
    return child_attributes_and_values
  end

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
    return geo_subjects
  end

  def extract_repository(mods, template)
    repository = {}
    mods_repository_node = @mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    return {} if mods_repository_node == nil
    template_repository_node = template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    repository_attributes = extract_attributes(mods_repository_node, template_repository_node)
    repository = {'lo:repository' => mods_repository_node.content}.merge!(repository_attributes)
    return repository
  end

  def extract_physicalLocation(mods)
    physicalLocation = {}
    mods_physicalLocation_nodes = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation")
    return {} if mods_physicalLocation_nodes == nil
    mods_physicalLocation_nodes.each do |p|
      physicalLocation.merge!({'lo:physicalLocation' => p.content}) if p['type'] != 'repository'
    end
    return physicalLocation
  end

  def extract_purl(mods)
    purl = {}
    purl = mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url[@usage='primary display']")
    return {} if purl == nil
    return {'lo:purl' => purl.content}
  end

  def extract_url(mods)
    url = {}
    mods_urls = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url")
    mods_urls.each do |u|
      url.merge!({'lo:url' => u.content}) if u['usage'] != 'primary display'
      url.merge!({'lo:url:displayLabel' => u['displayLabel']}) if u['displayLabel'] != nil
    end
    return url
  end

  def extract_relatedItem(mods, template)
    relatedItems = {}
    mods_relatedItem_nodes = mods.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    return {} if mods_relatedItem_nodes == nil
    template_relatedItem_nodes = template.xpath("//#{@ns}:mods/#{@ns}:relatedItem")
    mods_relatedItem_nodes.each_with_index do |ri, i|
      next if ri.at_xpath(".//#{@ns}:typeOfResource")['collection'] == "yes"
      relatedItems.merge!(extract_attributes(ri, template_relatedItem_nodes[i]))
      relatedItems.merge!(process_mods_elements(ri, template_relatedItem_nodes[i], ".//"))
    end
    return relatedItems
  end
end
