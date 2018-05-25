#!/usr/bin/bash
######################################################################################
#
# File	  : run_baypass.pl
# History : 5/4/2018  Created by Kevin Freeman(KF)
#		  : 5/11/2018 Added further logic
#
#######################################################################################
#
# This script combines multiple scripts to form an automated pipeline for analyzing
# a batch of VCFs with Baypass. The script is meant to be run in a folder called
# run_baypass with a "results_final" directory in its parent directory that contains all the 
# necessary input files. The required scripts should be in the same parent directory 
# as the run_baypass directory. It takes no arguments.
# 
#######################################################################################
#
# Example file tree with required scripts, input files, and directories:
# (Note --- converted_files, baypass_results, and log_files 
# directories and files are created during execution of the script)
# .
# |------results_final
# |       	|-------xxxx_Invers_indFILT.txt
# |			|------xxxx_Invers_ScanResults.txt
# |			|------xxxx_Invers_VCFallFILT.vcf.gz
# |			|------xxx_baypass_results.txt (created by script)
# |
# |----run_baypass     
# |		|---converted_files     (created by script)
# |  	|	|------xxxx_Invers_VCFallFILT.covar
# |		|	|------xxxx_Invers_VCFallFILT.geno
# |		|	|------xxxx_Invers_VCFallFILT_PRUNED.covar
# |		|	|------xxxx_Invers_VCFallFILT_PRUNED.geno
# |		|-----baypasss_results     (created by script)
# |		|	. (many files, see baypass 2.1 documnetation for more info)
# |		|	.
# |		|	. 
# |		|-----log_files            (created by script)
# |		|	|------xxxx_baypass_err.txt
# |		|	|------xxxx_baypass_log.txt					
# |		|		
# |     |-----run_baypass.sh
# |----vcf2baypass.pl
# |----pruneSNPs.pl
# |----getTableOfBaypassResults.pl					
#
#######################################################################################
SECONDS=0

mypath="/home/kevin/LOTTERHOS_LAB/UsefulScripts/Conversion_Scripts/run_baypass"
ncpus=3
start=10900
finish=$(($start + $ncpus-1))
echo $start $finish
declare -A npopHash    # declare an associative array to store # of populations for each file
function call_baypass_no_mat { 
	cd $mypath
	file_name=$1
	out_suffix=$2
	i=$3
    
    # convert vcf to baypass format, store npop in associative array (hash)
    npopHash=( [$i]="$(perl ../baypass_scripts/vcf2baypass.pl -vcf ../results_final/${i}${file_name} \
    -pop ../results_final/${i}_Invers_indFILT.txt \
    -colGroup 5 -colEnv 4 -colPheno 3 -colInFinal 6 \
    -outGeno ./converted_files/${i}_Invers_VCFallFILT$out_suffix \
    -outCovar ./converted_files/${i}_Invers_VCFallFILT$out_suffix)")

    # run baypass
    g_baypass -npop ${npopHash[$i]} \
     -gfile ./converted_files/${i}_Invers_VCFallFILT${out_suffix}.geno \
     -efile ./converted_files/${i}_Invers_VCFallFILT${out_suffix}.covar -scalecov \
     -outprefix ./baypass_results/${i}${out_suffix} -ncpus 4\
     >>./log_files/${i}_baypass_log.txt 2>>./log_files/${i}_baypass_err.txt
}
cd $mypath
# create necessary directories for organization
mkdir -p ./log_files
mkdir -p ./converted_files
mkdir -p ./baypass_results

# run baypass on all the SNPs
echo -e "\n############## Running scripts on all snps ######################################"
for i in $(seq $start $finish)
do 
	echo -e "\n$i"
	if [ -f ../results_final/${i}_Invers_VCFallFILT.vcf'.gz' ]; then
    		gunzip ../results_final/${i}'_Invers_VCFallFILT.vcf.gz'
    	fi
    if [ ! -f  ../results_final/${i}_Invers_VCFallFILT.vcf ]; then
    	echo "file not found"
    	continue
    	fi
    call_baypass_no_mat "_Invers_VCFallFILT.vcf" "" $i

# prune the snps and run baypass again on the pruned files
	echo -e "\n############ Pruning SNP files, running scripts on pruned files #################"
	echo -e "\n"$i
	cd ../results_final                                     # temporarily store pruned files in results_finals
    if [ ! -f  ./${i}_Invers_ScanResults.txt ]; then
    	echo "Scan results for ${i} not found"
    	continue
    fi 
	perl ../baypass_scripts/pruneSNPs.pl -scan ./${i}_Invers_ScanResults.txt \
	 -vcf ./${i}_Invers_VCFallFILT.vcf
	call_baypass_no_mat "_Invers_VCFallFILT.pruned.vcf" "_PRUNED" "${i}"

# run baypass again, this time using the pruned covar matrix from the last step
	
	cd $mypath
	gfileName="_Invers_VCFallFILT.geno"
	efileName="_Invers_VCFallFILT.covar"
	omegaFile="_PRUNED_mat_omega.out"

	echo -e "\n########## Running baypass on all SNPs with pruned matrix #########################"
	call_baypass_no_mat "_Invers_VCFallFILT.vcf" "" $i
	echo -e "\n"$i
	if [ ! -f  ./converted_files/${i}$gfileName ]; then
    	echo "Geno file for ${i} not found"
    	continue
    fi 
    if [ ! -f  ./converted_files/${i}$efileName ]; then
    	echo "env file for ${i} not found"
    	continue
    fi
    if [ ! -f  ./baypass_results/${i}$omegaFile ]; then
    	echo "Omega matrix file for ${i} not found"
    	continue
    fi
    g_baypass -npop ${npopHash[$i]} -gfile ./converted_files/${i}$gfileName \
    -efile ./converted_files/${i}$efileName -scalecov \
    -omegafile ./baypass_results/${i}$omegaFile \
    -outprefix "./baypass_results/${i}_ALL_PRUNED_MAT" -ncpus 4 \
    >>./log_files/${i}_baypass_log.txt 2>>./log_files/${i}_baypass_err.txt
    rm ../
done
# pull out analysis results and store in a table
echo -e "\n################ Putting Results into Tables ##############################"
cd ${mypath}/baypass_results
pwd
perl ../../baypass_scripts/getTableOfBaypassResults.pl -start $start -finish $finish
echo -e "\n\nDone. Analysis took $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min"
exit 0
