require 'rubygems'
require 'nokogiri'

# this script compiles XML descriptive metadata records coming from druid-named files into one file
# the required wrappers for Argo's MODS bulk upload are added

# druid-named files are defined as:
# [druid].xml, e.g. bb020sf5359.xml
# druid:[druid], e.g. druid:bb020sf5359

# example wrapper

# <xmlDocs xmlns="http://library.stanford.edu/xmlDocs" datetime="YYYY-MM-DD HH:MM:SSAM" sourceFile="filename.xml">
#  <xmlDoc id="descMetadata" objectId="#{druid}">
#    <mods>
#        ...
#    </mods>
#  </xmlDoc>
# </xmlDocs>

# to run the script, it needs two input parameters:
# 1. the folder of files to process
# 2. the filename for the new file

# the new file is written to the folder of files to process by default, unless you specify another location (a relative path) from this pwd

# command to run the script:
# ruby compile_wrap_descMD.rb <path to folder of files to process> <new filename>

folder = ARGV[0]
descMD = ARGV[1]

time = Time.now.strftime('%Y-%m-%d %I:%M:%S%p')

# change working directory to folder for processing files
Dir.chdir(folder) do
  # creates a new file for the compiled records
  newFile = File.new(descMD.to_s, 'w')
  newFile.write("<xmlDocs xmlns=\"http://library.stanford.edu/xmlDocs\" datetime=\"#{time}\" sourceFile=\"#{descMD}\">")

  # read the filenames in directory into an array for looking up
  filenames = Dir.entries('.') #=> ["bc849vk0855.xml", "bc994zz9154.xml"]

  # iterate through filenames
  filenames.each do |file|
    if file =~ /[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}\.xml/
      # get druid from filename
      druid = file.gsub(/\.xml/, '')

      # open druid-named files
      doc = Nokogiri::XML(open(file.to_s))
      record = doc.root

      # add xmlDoc wrapper
      newFile.write("<xmlDoc id=\"descMetadata\" objectId=\"#{druid}\">" + record.to_xml + '</xmlDoc>')

    elsif file =~ /druid.[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/
      # get druid from the filename
      druid = file.gsub(/druid./, '')

      # open druid-named files
      doc = Nokogiri::XML(open(file.to_s))
      record = doc.root

      # add xmlDoc wrapper
      newFile.write("<xmlDoc id=\"descMetadata\" objectId=\"#{druid}\">" + record.to_xml + '</xmlDoc>')

    end
  end

  newFile.write('</xmlDocs>')
end
