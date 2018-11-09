version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.name        =  'reverse_modsulator'
  s.version     =  version
  s.summary     =  "Produces replayable spreadsheet from MODS XML."
  s.description =  "Tools and libraries for working with metadata spreadsheets and MODS."
  s.authors     =  ["Arcadia Falcone"]
  s.email       =  'arcadia@stanford.edu'
  s.files       =  Dir["{lib}/**/*", "README.md"]
  s.test_files  =  Dir["spec/**/*"]
  s.homepage    =  'https://github.com/sul-dlss/content_management_scripts/reverse_modsulator'
  s.license     =  'Apache-2.0'
  s.platform    =  Gem::Platform::RUBY
  s.executables << 'reverse_modsulator'

  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rspec', '>= 3.0'
end
