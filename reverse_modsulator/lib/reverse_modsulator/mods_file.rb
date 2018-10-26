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

    @paired_code_text_elements = {
      'role' => 'roleTerm'
    }


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
    @column_hash.merge!(extract_subjects)
    @column_hash.merge!(extract_repository(mods, template))
    @column_hash.merge!(extract_physicalLocation(mods, template))
    @column_hash.merge!(extract_self_value(mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:shelfLocator"), template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:shelfLocator")))
    @column_hash.merge!(extract_purl(mods, template))
    @column_hash.merge!(extract_urls(mods, template))
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
      child_mods_nodes = mods_node.xpath("#{@ns}:#{name}")
      child_template_nodes = template_node.xpath("#{@ns}:#{name}")
      child_mods_nodes.each_with_index do |n, i|
        child_attributes_and_values.merge!(extract_attributes(n, child_template_nodes[i]))
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
    child_element_name = @paired_code_text_elements[mods_node.name]
    ['text', 'code'].each do |x|
      header_code = template_node.at_xpath("#{@ns}:#{child_element_name}[@type='#{x}']")
      value = mods_node.at_xpath("#{@ns}:#{child_element_name}[@type='#{x}']")
      next if header_code == nil || value == nil
      code_text_values[header_code.content.strip.slice(2..-3)] = value.content
      code_text_values.merge!(extract_attributes(value, header_code))
    end
    return code_text_values
  end

  def extract_subjects
    subjects = {}
    mods_subject_name_nodes, template_subject_name_nodes = get_subject_name_nodes
    mods_subject_other_nodes, template_subject_other_nodes = get_subject_other_nodes(mods_subject_name_nodes)
    mods_subject_name_nodes.each_with_index do |sn, i|
     subjects.merge!(extract_subject_values_and_attributes(sn, template_subject_name_nodes[i]))
    end
    mods_subject_other_nodes.each_with_index do |su, i|
     subjects.merge!(extract_subject_values_and_attributes(su, template_subject_other_nodes[i]))
    end
    return subjects
  end

  def get_subject_name_nodes
    mods_subject_name_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:subject/#{@ns}:name|//#{@ns}:mods/#{@ns}:subject/#{@ns}:titleInfo").map {|x| x.parent}.uniq
    template_subject_name_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:subject").grep(/sn[\d]+:/)
    return mods_subject_name_nodes, template_subject_name_nodes
  end

  def get_subject_other_nodes(mods_subject_name_nodes)
    mods_subject_other_nodes = @mods.xpath("//#{@ns}:mods/#{@ns}:subject")
    mods_subject_other_nodes.map {|x| mods_subject_other_nodes.delete(x) if mods_subject_name_nodes.include?(x)}
    template_subject_other_nodes = @template.xpath("//#{@ns}:mods/#{@ns}:subject").grep(/su[\d]+:/)
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

  def extract_repository(mods, template)
    repository = {}
    mods_repository_node = mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    return {} if mods_repository_node == nil
    template_repository_node = template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type='repository']")
    repository_attributes = extract_attributes(mods_repository_node, template_repository_node)
    repository = {'lo:repository' => mods_repository_node.content}.merge!(repository_attributes)
    return repository
  end

# TODO: xpath negation not working
  def extract_physicalLocation(mods, template)
    physicalLocation = {}
    mods_non_repository_node = mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type!='repository']")
    return {} if mods_non_repository_node == nil
    template_non_repository_node = template.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:physicalLocation[@type!='repository']")
    non_repository_attributes = extract_attributes(mods_non_repository_node, template_non_repository_node)
    physicalLocation = {'lo:physicalLocation' => mods_non_repository_node.content}.merge!(non_repository_attributes)
    return physicalLocation
  end

  def extract_purl(mods, template)
    purl = {}
    purl = mods.at_xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url[@usage='primary display']")
    return {} if purl == nil
    return {'lo:purl' => purl.content}
  end

#TODO: xpath negation not working
  def extract_urls(mods, template)
    urls = {}
    mods_urls = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url[@usage!='primary display']|//#{@ns}:mods/#{@ns}:location/#{@ns}:url[not(@usage)]")
    template_urls = mods.xpath("//#{@ns}:mods/#{@ns}:location/#{@ns}:url[@usage!='primary display']|//#{@ns}:mods/#{@ns}:location/#{@ns}:url[not(@usage)]")
    mods_urls.each_with_index do |u, i|
      urls.merge!(extract_attributes(u, template_urls[i]))
      urls.merge!(extract_self_value(u, template_urls[i]))
    end
    return urls
  end

end
