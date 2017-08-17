# Analyzes MODS XML files in directory, checking for records missing name or subject elements, or
# with name or subject elements missing authority attributes
# Usage: ruby analyze_mods.rb input_directory output_file
# Output is tab-delimited text file

require 'nokogiri'

inputdir = ARGV[0]
@outfile = File.open("#{ARGV[1]}", 'w')

# Set error descriptions for output
no_name = 'No <name> element in record'
no_name_auth = 'Name missing authority attributes'
no_subject = 'No <subject> element in record'
no_subject_name_auth = 'Name subject missing authority attributes'
no_subject_topic_auth = 'Topic subject missing authority attributes'
no_subject_geo_auth = 'Geographic subject missing authority attributes'
no_subject_temp_auth = 'Temporal subject missing authority attributes'

# Check whether existing subject element has authority attribute
def check_subject_auth(druid, subject_type, error)
	subject_set = @doc.xpath("/xmlns:mods/xmlns:subject/xmlns:#{subject_type}")
	return if subject_set.empty?
	subject_set.each do |subject|
		unless subject.key?('authority') || subject.parent.key?('authority')
			@outfile.write("#{druid}\t#{error}\t#{subject.content}\n")
		end
	end
end

# Iterate over MODS XML files in input directory
Dir.foreach("#{inputdir}") do |file|
	# Skip if directory
	next if File.directory? file
  # Open input file as Nokogiri doc
	filename = File.join("#{inputdir}", "#{file}")
	@doc = Nokogiri::XML(open("#{filename}"))
	# Extract druid from file name
	/(druid[:_])?(?<druid>.*)\.xml/ =~ file
	# Identify nodes matching mods/name/namePart, if any
	name_set = @doc.xpath('/xmlns:mods/xmlns:name/xmlns:namePart')
	# Write to output if no names found
	if name_set.empty?
		@outfile.write("#{druid}\t#{no_name}\t\n")
	else
		# Write to output if mods/name element lacks authority attribute
		name_set.each do |name|
			unless name.parent.key?('authority')
				@outfile.write("#{druid}\t#{no_name_auth}\t#{name.content}\n")
			end
		end
	end
	# Identify nodes matching mods/subject
	subject_set = @doc.xpath('/xmlns:mods/xmlns:subject')
	# Write to output if no subjects found
	if subject_set.empty?
		@outfile.write("#{druid}\t#{no_subject}\t\n")
	else
		# Identify notes matching mods/subject/name/namePart
		name_subject_set = @doc.xpath('/xmlns:mods/xmlns:subject/xmlns:name/xmlns:namePart')
		# Write to output if both mods/subject and mods/subject/name lack an authority attribute
		name_subject_set.each do |name_subject|
			unless name_subject.parent.key?('authority') || name_subject.parent.parent.key?('authority')
				@outfile.write("#{druid}\t#{no_subject_name_auth}\t#{name_subject.content}\n")
			end
		end
		# Write to output if other (non-name) instances of mods/subject lack an authority attribute
		check_subject_auth(druid, "topic", no_subject_topic_auth)
		check_subject_auth(druid, "geographic", no_subject_geo_auth)
		check_subject_auth(druid, "temporal", no_subject_temp_auth)
	end
end
