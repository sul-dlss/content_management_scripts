require 'rubygems'

# this script renames filenames
# input file (mapping file) is a comma separated file of old filename values and new filename values
# the filename values in the mapping file should include the extension, otherwise your files will not have extensions
# example: old.xml,new.xml
# it will read the directory of files you want name changes and compare that with the mapping file
# it will report out filenames in your directory that do not exist in the mapping file

# run the script:
# ruby rename_files.rb <mapping_file> <relative path of folder where filenames need to be changed>

# get the filename of the mapping file from user input
# mapping_file = "test_rename_files.csv"
mapping_file = ARGV[0]

# folder name where files are that need name changes
# folder = "test"
folder = ARGV[1]

# initiate hash for the mapping file
old_name_new_name = {}

# reads the mapping file into the old_name_new_name hash
File.open(mapping_file.to_s).each do |line|
  key, value = line.chomp.split(',')
  old_name_new_name[key] = value
end

# # test hash assignment
# old_name_new_name.each_key do |old_name|
# 	puts "#{old_name} #{old_name_new_name[old_name]}"
# end

# change working directory to there
Dir.chdir(folder) do
  # file to write errors where the filename is in the directory but not the mapping file
  unchanged_names = File.new('unchanged_names.txt', 'w+')

  # read the filenames in directory into an array for looking up
  filenames = Dir.entries('.') #=> ["0004A.xml", "0004001.xml"]
  # filenames.each { | file |
  # 	puts file
  # }

  # iterate through filenames listing and look it up in the mapping file
  # to find the matching new_name
  filenames.each do |old_name|
    # remove the file extension
    # old_name = file.gsub(/\.xml/,"")

    # lookup filenames in the hash
    # new_name = $old_name_new_name.fetch[old_name]
    if old_name_new_name.key?(old_name)
      new_name = old_name_new_name[old_name]
      # puts "#{new_name}"
      File.rename(old_name.to_s, new_name.to_s)

    # need to figure out how to compare the mapping file's old filenames to the filenames
    # in the directory for reporting.

    else
      unchanged_names.puts old_name.to_s
    end
  end
end

# $new_name_old_name.each_key do | new_name |
#   script.puts "mv ../descMD/#{$new_name_old_name[new_name]}.xml ../descMD/#{new_name}.xml"
#   end
# filenames.close
