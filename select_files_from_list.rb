# Copies selected files from one directory to another based on list
# Usage: ruby select_files_from_list.rb list.txt all_file_directory_in/ selected_file_directory_out/
# List should be text file with one filename per line

require 'fileutils'

# Check for existence of input and output directories
if !Dir.exist?(inputdir)
  puts "#{inputdir} does not exist"
  exit
elsif !Dir.exist?(outputdir)
  Dir.mkdir(outputdir)
end

list_file = ARGV[0]
input_dir = ARGV[1]
output_dir = ARGV[2]

filelist = []

# Get names of files to copy
File.foreach("#{list_file}") do |line|
  filename = line.strip
  filelist << filename
end

Dir.chdir(input_dir)

# Copy the files on the list to the output directory
filelist.each do |filename|
  if File.exist?(filename)
    FileUtils.cp filename, File.join("..", "#{output_dir}")
  else
    # Warn if listed file not present
    puts "File #{filename} not in #{input_dir}"
  end
end
