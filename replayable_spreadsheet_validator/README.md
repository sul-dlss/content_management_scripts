# Replayable spreadsheet validator

Validates a replayable spreadsheet (.xlsx, .xls, or .csv) against the modsulator template and checks for other problems with the metadata. If desired, an alternate template may be specified as a third argument; otherwise, the modsulator_template.xml in the same directory as the script is used.

The validator classes issues into failures, errors, warnings, and information. Failures prevent the spreadsheet from being parsed for validation; errors mean system or schema metadata requirements are not met; warnings mean metadata recommendations are not met; information means the data suggests an error may be present, or is missing from a non-essential field.

Usage: ruby replayable_spreadsheet_validator.rb replayable_spreadsheet.xlsx report.txt [optional: alternate_modsulator_template.xml]

Dependency: roo

## Validation criteria

### Failure
* File extension is .xlsx, .xls, or .csv
* Header row beginning with "druid" and "sourceId" is present
* Spreadsheet does not include invalid characters

### Error
* No duplicate headers
* No blank rows within the data
* No line breaks or control characters in cell values
* No duplicate druids
* No data rows without druids
* Druids match alphanumeric pattern
* Required fields have data
..* Title (ti1:title)
..* Type of resource (ty1:typeOfResource)
* MODS controlled field values match specified vocabulary
..* Title type (tiX:type)
..* Name usage (na1:usage)
..* Type of resource (ty1:typeOfResource)
..* Manuscript (ty1:manuscript)
..* All dates: keyDate, qualifier, point, encoding
..* Issuance (orX:issuance)
..* Subject types (snX:p1:nameType, suX:pX:type)
* No more than one keyDate is declared
* All subject values have types

### Warning
* No cell values beginning with an unclosed double quotation mark
* Date range point values are present if two dates are given
* Date keyDate, qualifier, point, and encoding field have a value only if the corresponding date field does
* A keyDate is declared
* No subject types lack corresponding subjects
* Each record has a value in the lo:purl field

### Information
* Headers in spreadsheet also appear in modsulator XML template
* All columns with data have headers
* No duplicate or missing source IDs
