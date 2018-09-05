#!/usr/bin/python
# coding: utf-8
####################################################################################
#
# File    : writeCSVtoMD.py
# History : Created Sept 5, 2018 by Kevin Freeman
#
####################################################################################
#
# This is a short script that takes a table 
# downloaded from an excel spreadsheet or similar
# in CSV format (or you can specify a different 
# separator) and writes the information to a 
# markdown formatted table. The table is printed
# to standard out and can be added to another 
# document (ex a github webpage) with the '>>'
# operator.
#
# examples: 
#
# python3 writeCSVtoMD.py myTable.csv --header >> myWebpage.md 
#
# python3 writeCSVtoMD.py myTable.csv --columns col1,col2 --sep '\t' >> myWebpage.md
# 
####################################################################################
import argparse
import sys

parser = argparse.ArgumentParser(description='Convert a plaintext table to markdown')
parser.add_argument('csv', help = "file name where the table to convert is stored")
parser.add_argument('--header', help = "does the input file have a header?", 
                    action = "store_true")
parser.add_argument('--sep', help = "character(s) that separate the columns, default is ','", default = ",")
parser.add_argument('--columns', help = "names for the columns, required if the file does not have a header. Separate with ',' ex: Package,Version")
args = parser.parse_args()

csv         = args.csv
sep         = args.sep

if not args.header:
    try:
        colNames = args.columns.split(",")
    except:
        sys.exit('Error: no column names specified and no header found')


## small function that just adds pipes to the beginning and end of string
def addPipes(line):
    line =  " | ".join(line)
    return("| " + line + " |")

with open(csv, 'r') as f:
    first = True
    for line in f:
        line      = line.strip()
        splitLine = line.split(sep)
        
        if first:
            if args.header:
                ncol      = len(splitLine)
                hyphenLine= ["---"] * ncol
                hyphenLine= addPipes(hyphenLine)
                header    = addPipes(splitLine)
                outLines  = [header] + [hyphenLine]
            else:
                ncol      = len(colNames)
                hyphenLine= ["---"] * ncol
                hyphenLine= addPipes(hyphenLine)
                header    = addPipes(colNames)
                outLines  = [header] + [hyphenLine]
                outLines.append(addPipes(splitLine))
            
            first = False
        else: 
            outLines.append(addPipes(splitLine))
            

for line in outLines:
    print(line)

