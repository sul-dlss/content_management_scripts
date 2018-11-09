# Reverse modsulator

Processes MODS files and generates a replayable spreadsheet using the same template as the modsulator. Includes all elements in current modsulator template except for part and ext.

Input: Directory containing MODS files (one record per file) with filename pattern druid:[druid].xml or [druid].xml. Non-XML files in the directory are ignored.
Output: Tab-delimited file with replayable spreadsheets and one row of data per input file. Druid values are derived from the filenames.

## To install:
```git checkout https://github.com/sul-dlss/content_management_scripts.git
cd content_management_scripts/reverse_modsulator
bundle install
gem build reverse_modsulator.gemspec
gem install ./reverse_modsulator-x.x.x.gem```

## To use:
```reverse_modsulator path/to/modsfiles outfile.txt```
