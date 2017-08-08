Split spreadsheet into multiple CSV files
-----------------------------------------

Usage: ruby split_spreadsheet.rb path/to/inputfile.xlsx path/to/outputdirectory

Requires "roo" gem for spreadsheet parsing. Use "gem install roo" to install.

Default split size is 1000 lines. Use -n [number] after the output directory to set a different size.
For example, "ruby split_spreadsheet.rb path/to/inputfile.xlsx path/to/outputdirectory -n 500" will produce output files of 500 lines each.

Use "ruby split_spreadsheet.rb help" to view this information.
