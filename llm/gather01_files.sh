#!/bin/bash

# we want to print a bunch of files in the format:
# // START OF <filename>
# <contents of file>
# // END OF <filename>
# so that we can have them as context in a large language model

# we are interested in the following files:
# recursively all *.go files in ../
# recursively all *.md files in ../ 
# *.txt files in ../log

for file in $(find ../ -name '*.go' -o -name '*.md' -o -name '*.txt'); do
    echo "// START OF $file"
    cat $file
    echo "// END OF $file"
done