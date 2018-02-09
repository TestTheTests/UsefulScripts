#!/bin/bash
set -e
set -u
set -o pipefail

if [ $1 = "-h" ]
then
	echo "////////////////////////////////////////////////////////////////////////"
	echo "usage: concatfiles.sh file_identifier output_filename -f 1"
	echo "where -f flags whether you want to include file names in separate column (0=no; 1=yes)"
	echo "example: concatfiles.sh outputMut outputMut_concat -f 1"
	echo "file_identifier must be expression unique to files you would like to concatenate"
	echo "output_filename must be unique"
	echo "////////////////////////////////////////////////////////////////////////"
	exit 1
fi

if [ "$#" -lt 4 ] # are there less than 2 arguments?
then
	echo "error: too few arguments, you provided $# arugments, 4 are required"
	echo "usage: concatfiles.sh file_identifier output_filename -f 1"
	echo "where -f flags whether you want to include file names in separate column"
	exit 1
fi

file_identifier="$1"
output_filename="$2"

if [ -n "$(find . -maxdepth 1 -name "${file_identifier}*.vcf")" ]
then
	echo "error: cannot concatenate vcf files"
	echo "adjust unique identifier or move vcf files to different directory"
	exit 1
fi

if [ -f ${output_filename} ]
then
	echo "error: output filename already exists"
	echo "please use unique output name"
	exit 1
fi

if [ -n "$(echo "$file_identifier" | grep "^concat$")" -o -n "$(echo "$file_identifier" | grep "^files$")" ]
then 
	echo "error: cannot use concat or files as unique identifier"
	exit 1
fi


all_files=$(find . -maxdepth 1 -name "*${file_identifier}*")

#Define first file in list of files
first_file=$(find . -maxdepth 1 -name "*${file_identifier}*" | head -1)

#Exit if there is no first file (i.e. nothing found)
if [ -z "${first_file}" ]
then
        echo "unique identifier not found"
        echo "check identifier for errors"
        exit 1
fi

#Exit if there is an incorrect flag value
if [ $4 -ne 0 -a $4 -ne 1 ]
then
	echo "error: incorrect flag value"
	exit 1
fi

if [ $4 = "1" ]
then
	all_files=$(find . -maxdepth 1 -name "*${file_identifier}*")
	raw_contents=$""
	fileIDlist=$""
	line_ending=$'\n'
	for file in $(echo "${all_files}")
	do
		tailed=$(tail -n +2 "${file}")
		x=$(echo "${tailed}" | grep -v "^\s*$" | wc -l | awk '{print $1}')
		raw_contents=${raw_contents}${line_ending}$(echo "$tailed" | grep -v "^\s*$")
		fileIDlist=${fileIDlist}${line_ending}$(for i in $(seq "$x"); do echo "${file}"; done)
	done 

	#Define file contents
	file_contents=$(paste -d ' ' <(echo "${fileIDlist}") <(echo "${raw_contents}"))

	#Add header of first file
	head -1 ${first_file} > ${output_filename}

	#Add column for FileID
	echo "FileID $(head -1 ${output_filename})" > ${output_filename}

	#Add rest of file contents
	echo "${file_contents}" | grep -v "^\s*$" >> ${output_filename}
	exit 1
fi

file_contents=$(find . -maxdepth 1 -name "*${file_identifier}*" | xargs -n 1 tail -n +2)

#Add header of first file
head -1 ${first_file} > ${output_filename}

#Add rest of file contents
echo "${file_contents}" | grep -v "^\s*$" >> ${output_filename}
