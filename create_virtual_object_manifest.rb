#!/usr/bin/ruby env

# Two input files:
# parent_with_simple.txt contains objects with metadata - parent virtual
# objects and simple objects; it is derived from the metadata workform
# child_with_simple.txt contains objects with associated files - children of a
# parent virtual object and simple objects; it is derived from an Argo report
# Both input files should contain druid and sourceID in the first two columns,
# in that order
#
# One output file:
# outfile.txt contains the virtual object (parent) druid in the first column,
# and the druids for the associated child objects, sorted by sourceid, in the
# subsequent columns
#
# Usage:
# >ruby create_vo_manifest.rb parent_with_simple.txt child_with_simple.txt outfile.txt


require 'set'

def get_data(filename)
	# Extract data from input file to populate create set and add to shared hash
	# Initiate set
	file_set = Set.new
	# Process first two columns of each line
	File.foreach(filename) do |line|
		druid, sourceid = line.chomp.split("\t")[0, 2]
		# Skip row if first column value does not match druid character pattern
		if !validate(druid)
			next
		end
		# Add druid/sourceid pair to shared hash
		@datadict[sourceid] = druid
		file_set.add(sourceid)
	end
	# Return set of sourceids in file
	return file_set
end

def validate(druid)
  # Boolean to determine if a value matches the druid pattern
  # Check if value is a string; return False if not
  if !druid.is_a? String
    return false
  end
  # Check string against druid character pattern; return True if match,
  # False if not
  if druid =~ /^[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}$/
    return true
  else
    return false
  end
end

# Get the input and output filenames from the user
psfile = ARGV[0]
csfile = ARGV[1]
fileout = ARGV[2]

# Initiate shared hash that pairs sourceids with druids
@datadict = Hash.new

# Populate shared hash and return set of sourceids in each input file
parent_plus = get_data(psfile)
child_plus = get_data(csfile)

# Get set of simple objects (common to both files)
simple = parent_plus.intersection(child_plus)
# Get set of parent objects (parent file with simple objects removed)
parent = parent_plus.difference(simple)
# Get set of child objects (child file with simple objects removed)
child = child_plus.difference(simple)

# Open output file
File.open("#{fileout}", "w") do |f|
	# Create sorted array of sourceids for virtual object parents
	sorted = parent.to_a.sort
	sorted.each do |p|
		# If parent sourceid ends with _000, remove to get base sourceid for children
		if p =~ /_[0]*$/
			p_base = p.sub(/_[0]*$/, '')
		# Otherwise use parent sourceid as base
		else
			p_base = p
		end
		# Create array of sourceids that start with parent base
		# These are the child objects associated with that parent
		group = child.select do |c|
			c.start_with?(p_base)
		end
		# Assumes that sorting the sourceids will produce the correct order for the
		# child objects
		group.sort!
		# Initiate array and populate with the druids matching the child sourceids
		group_druids = Array.new
		group.each do |x|
			group_druids << @datadict[x]
		end
		# Write list with parent druid followed by child druids to output file
		f.write(@datadict[p] + "\t" + group_druids.join("\t") + "\n")
	end
end
