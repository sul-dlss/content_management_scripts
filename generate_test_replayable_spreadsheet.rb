require 'csv'

template = "#{ARGV[0]}"
outdir = "#{ARGV[1]}"

def sub_fixed_values(header_codes, pattern, sub_value)
  fixed_value_fields = header_codes.keys.select {|x| x.match(pattern)}
  fixed_value_fields.each {|f| header_codes[f] = sub_value}
end

def output_fields_by_file(header_codes, fields, filename)
  CSV.open(filename, "wb") do |csv|
    headers = ["druid", "sourceId"] + fields
    values = ["aa111aa1111", "sul:sourceId"] + fields.map {|f| header_codes[f]}
    unless headers.include?("ti1:title")
      headers << "ti1:title"
      values << "ti1:title"
    end
    unless headers.include?("ty1:typeOfResource")
      headers << "ty1:typeOfResource"
      values << "text"
    end
    csv << headers
    csv << values
  end
end

header_codes = {}
order = []

puts "Scanning template..."
File.foreach(template) do |line|
  fields = line.scan(/\[\[(.+?)\]\]/).flatten
  next if fields == nil
  fields.each do |f|
    header_codes[f] = f
    order << f unless order.include?(f)
  end
end

puts "Substituting controlled values..."
# title
sub_fixed_values(header_codes, /ti\d+:type/, "alternative")

# name & subject name type
sub_fixed_values(header_codes, /na\d+:usage/, "primary")
sub_fixed_values(header_codes, /na\d+:type/, "personal")
sub_fixed_values(header_codes, /sn\d+:p1:nameType/, "personal")

# type of resource
sub_fixed_values(header_codes, /ty1:manuscript/, "yes")
sub_fixed_values(header_codes, /typeOfResource/, "text")

# language
sub_fixed_values(header_codes, /la\d+:authority/, "iso639-2b")

# date
sub_fixed_values(header_codes, /dt.*?[Kk]eyDate/, "")
sub_fixed_values(header_codes, /^dt:dateCreatedKeyDate$/, "yes")
sub_fixed_values(header_codes, /dt.*?[Ee]ncoding/, "w3cdtf")
sub_fixed_values(header_codes, /dt.*?[Qq]ualifier/, "approximate")
sub_fixed_values(header_codes, /dt.*?[a-z][Pp]oint/, "start")
sub_fixed_values(header_codes, /dt.*?\d[Pp]oint/, "end")

# origin info
sub_fixed_values(header_codes, /placeCode/, "marcgac")
sub_fixed_values(header_codes, /issuance/, "continuing")

# physical description
sub_fixed_values(header_codes, /reformattingQuality/, "access")
sub_fixed_values(header_codes, /digitalOrigin/, "reformatted digital")

# subject
sub_fixed_values(header_codes, /s[nu]\d+:p\d:type/, "topic")

# related item
sub_fixed_values(header_codes, /ri\d+:type/, "host")

puts "Selecting fields by output file..."
title_fields = order.select {|ti| ti.match(/^ti\d/)}
name_fields = order.select {|na| na.match(/^na\d/)}
type_genre_fields = order.select {|tyge| tyge.match(/^ty\d|^ge\d/)}
origin_fields = order.select {|ordt| ordt.match(/^or[\d:]|^dt[\d:]/)}
language_fields = order.select {|la| la.match(/^la\d/)}
physdesc_fields = order.select {|ph| ph.match(/^ph\d/)}
abstract_toc_note_fields = order.select {|abtcno| abtcno.match(/^ab:|^tc:|^no\d/)}
subject_name_fields = order.select {|sn| sn.match(/^sn\d/)}
subject_other_fields = order.select {|su| su.match(/^su\d/)}
cartographics_id_loc_fields = order.select {|scidlo| scidlo.match(/^sc\d|^id\d|^lo:/)}
part_fields = order.select {|pt| pt.match(/^pt:/)}
related_fields = order.select {|ri| ri.match(/^ri\d/)}
ext_fields = order.select {|ex| ex.match(/^ext:/)}
admin_fields = order.select {|rc| rc.match(/^rc:/)}

puts "Generating output files..."
output_fields_by_file(header_codes, title_fields, "#{outdir}/title.csv")
output_fields_by_file(header_codes, name_fields, "#{outdir}/name.csv")
output_fields_by_file(header_codes, type_genre_fields, "#{outdir}/type_genre.csv")
output_fields_by_file(header_codes, origin_fields, "#{outdir}/origin.csv")
output_fields_by_file(header_codes, language_fields, "#{outdir}/language.csv")
output_fields_by_file(header_codes, physdesc_fields, "#{outdir}/physdesc.csv")
output_fields_by_file(header_codes, abstract_toc_note_fields, "#{outdir}/abstract_toc_note.csv")
output_fields_by_file(header_codes, subject_name_fields, "#{outdir}/subject_name.csv")
output_fields_by_file(header_codes, subject_other_fields, "#{outdir}/subject_other.csv")
output_fields_by_file(header_codes, cartographics_id_loc_fields, "#{outdir}/cartographics_id_loc.csv")
output_fields_by_file(header_codes, part_fields, "#{outdir}/part.csv")
output_fields_by_file(header_codes, related_fields, "#{outdir}/related.csv")
output_fields_by_file(header_codes, ext_fields, "#{outdir}/ext.csv")
output_fields_by_file(header_codes, admin_fields, "#{outdir}/admin.csv")
