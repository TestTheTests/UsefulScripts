# Conversion Scripts

This is a collection of scripts used to convert VCF files to other formats:
* [vcf2baypass.pl](#vcf2baypasspl)
* [vcf2H_scan.pl](#vcf2h_scanpl)
* [vcf2map.pl](#vcf2mappl)
* [pruneSNPs.pl](#prunesnpspl)
---


## vcf2baypass.pl

This script takes a vcf file and a corresponding population file, extracts the genotype information for each individual, groups the genotype information, and outputs a file that can be used in [BayPass](www1.montpellier.inra.fr/CBGP/software/baypass/files/BayPass_manual_2.1.pdf)

### Usage

`$ perl vcf2baypass.pl -vcf <yourFile.vcf> -pop <populationfile> -col_group 5 -outGeno "variantGenotypes"`

The -help option can be used to display usage information from the command line.

### Inputs

**VCF File:** Required. File in standard VCF format that you wish to convert. Can be either phased or unphased.

**Population File:**

Required. A file that gives population information corresponding to the individuals in your VCF. Format can vary but it must conform to the following rules:
* Each line in the file corresponds to one individual
* There must be the same number of individuals in the population file as in the VCF
* The individuals must be in the same order in both files
* One of the columns must be group - a number that tells which group the individual belongs to

**col_group:** Required. This is an integer that tells the script which column to look in for the group information. Numbering starts at 0.

**col_Env:** Optional. This is an integer that tells which column of the population file the environment variable is located in. This will 	 
	     cause the program to produce a covariate file with the environmental average value for each group. This covariate file is
	     necessary for certain modes of Baypass.

**col_Pheno:** Optional. You may also specify the column that the phenotype data is in. If both col_Env and col_Pheno are specified the 
	       covariate file will contain one line for each variable.   

**outGeno:** Optional. Prefix for the file to print the genotype information to. If no name is provided, the default is <name_of_vcf>

**outCovar:** Optional. Prefix for the file to print the covariate information to. If no name is provided, defaults to <name_of_vcf> 


### Outputs

One file in the proper format for a BayPass scan. Each row in the file is a position, each column is an allele count for a particular group. More information can be found in the [BayPass Manual](www1.montpellier.inra.fr/CBGP/software/baypass/files/BayPass_manual_2.1.pdf)

The number of populations is also printed to standard out. BayPass will ask you for this number when you run the scan.

If col_Env or col_Pheno was specified, a covariate file of the form <name_of_vcf>.covar will also be produced.


---



## vcf2H_scan.pl

This script is used to convert a phased VCF to an SNP file that can be used for [H-scan](https://www.dropbox.com/s/26i7mdos3w0gk41/H-scan.pdf?dl=0). 

### Usage

`$ perl vcf2H_scan.pl -vcf <yourFile.vcf> -outfile <yourOutfile>`

The -help option can be used to display usage information from the command line.

### Inputs

**VCF File:** Required. File in standard VCF format that you wish to convert. **Must be PHASED genotype data**.

**Outfile:** Optional. File name to print the ouput to. Defaults to <name_of_vcf.hscan> if no name is provided.

### Outputs

One file that can be used in H-scan. Each line in the file represents one SNP. The first entry in each line is the position of the SNP, followed by the genotypes of each sample. Examples and more information can be found in the [H-scan manual](https://www.dropbox.com/s/26i7mdos3w0gk41/H-scan.pdf?dl=0)



---



## vcf2map.pl

This script takes a file in VCF format and reformats the variant data into a .map file for use in [hapflk](https://forge-dga.jouy.inra.fr/projects/hapflk/wiki)

### Usage

`$ perl vcf2map.pl -vcf <yourFile.vcf> -outfile <yourOutfile>`

The -help option can be used to display usage infromation from the command line.

### Inputs

**VCF File:** Required. File to convert. Can be either phased or unphased data.

**Outfile:** Optional. File name to print the ouput to. Defaults to <name_of_vcf.map> if no name is provided.

### Outputs

One .map file for use in hapflk analysis. Each line is a variant and it contains the chromosome, the variant ID, and the bp coordinate. More information on the .map file format can 
be found in the [PLINK file format reference](https://www.cog-genomics.org/plink2/formats#map).




---



## pruneSNPs.pl

This script takes a file in VCF format and a file that indicates whether an allele is quasi independent or not. It takes all the quasi-independent alleles and prints them to a new VCF.

### Usage

`$ perl pruneSNPs.pl -vcf <yourFile.vcf> -scan <indicateQuasiIndependence.txt> -posCol 0 -chrCol 1 -indCol 3`

### Inputs

**VCF File:** Required. File to be pruned. Can be either phased or unphased.

**Scan File:** Required. Text file with results from a test for quasi-independence. Each line after the header should correspond to one allele. Also, it must have the following: 
* A 1 line header that includes "pos" "chrom", and "quasi_indep" column labels 
* A column that indicates the chromosome that the allele is on ("chrom")
* A column that indicates the position ("pos")
* A column that indicates whether the allele is quasi independent ("quasi_indep")  by a value of "TRUE" or "FALSE". "TRUE" means the allele is quasi independent

**outfile:** The file where you would like to store the pruned VCF. Defaults to <name_of_vcf.pruned.vcf>

### Outputs

A pruned VCF printed to outfile. A list of the indexes of the alleles that were kept, printed to a tab-delimited text file called "indexes_remaining.txt".

Example of indexes_remaining.txt if the 1st 10  alleles were kept:

0	1	2	3	4	5	6	7	8	9




---
