## Overview

Script to transform a spreadsheet into a tab-delimited file based on rules in a
mapping file.

Usage: ruby process_mapping.rb infile.xlsx outputdirectory mapfile.tsv
* infile.xlsx = Excel spreadsheet containing input data, with headers in first
row
* outputdirectory = directory for script output, one file per tab in input
spreadsheet, with the filename derived from the tab name
* mapfile.tsv = tab-delimited text file stating mapping rules in expected
syntax

The mapping syntax allows four different kinds of transformation:
1. **Simple mapping:** The value is transferred as-is to a field in the output data.
2. **Constant data:** A value given in the mapping itself is transferred to a field
in the output data, with no reference to the input data.
3. **Mapping as variables:** Variables are given as the input header in
curly brackets. This may be used to insert a mapped value into a constant string
(`{Dimensions} mm`) or to combine two or more input fields into a single output
field (`{Dimensions} {Units}`).
4. **Conditional output:** This works in conjunction with one of the three methods above. It states a dependency between two fields, such as that the variable mapping `{Dimensions} mm` should not be applied if the Dimensions input field does not have a value. This prevents the output " mm" when the Dimensions value is absent.

## Mapping syntax

The mapping file contains four columns (three if no conditionals are used).

The first column gives the target field -- the field that data will be mapped
to in the output. Values of this column must be unique.

The second column indicates the source of the data. Its exact syntax depends on the transformation type, as described below. If this column is left blank, the field named in the first column will be created in the output, but will not contain any data.
* **Simple mapping:** the second column contains the header of the column in the
input that contains the data.
* **Constant data:** the second column contains the data string to write to output.
* **Mapping as variables:** the second column contains a statement including
variables, which are given as input headers in curly brackets.

The third column names the transformation type. If the second column is blank,
this column should be blank as well. Otherwise, enter the value as given below.
* **Simple mapping:** "map"
* **Constant data:** "string"
* **Mapping as variables:** "complex"

The fourth column is optional and states a condition that must be met for the
rule to generate output. The value of this column is the header of the input
column that must have a value for the rule to be applied. If the given input
field does not have a value, a blank string is output instead.

## Example data

#### Input
ID  | Title | Dimensions (mm)
----|-------|-----------
1 | Portrait #1 |
2 | Portrait #2 | 55 x 72
3 | Portrait #3 | 88 x 44

#### Mapping
(ignore blank first row)

   |   |   |   |
---|---|---|---
portraitID | ID | map |
title | Title | map |
extent | {Dimensions (mm)} mm | complex | Dimensions (mm)
repository | Stanford University Libraries | string |

#### Output
portraitID | title | extent | repository
-----------|-------|--------|-----------
1 | Portrait #1 | | Stanford University Libraries
2 | Portrait #2 | 55 x 72 mm | Stanford University Libraries
3 | Portrait #3 | 88 x 44 mm | Stanford University Libraries

See the files in the fixtures directory for more sample input, mapping, and
output.
