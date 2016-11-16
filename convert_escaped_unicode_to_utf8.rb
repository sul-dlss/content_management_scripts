# usage: ruby convert_escaped_unicode.rb infile.txt outfile.txt

infile = ARGV[0]
outfile = File.open("#{ARGV[1]}", 'w')

File.foreach("#{infile}") do |line|
  outfile.write(line.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")})
end

outfile.close
