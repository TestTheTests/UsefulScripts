# Conversion Scripts

This is a collection of scripts used to convert VCF files to other formats:
* [vcf2baypass.pl](#vcf2baypasspl)
* [vcf2H_scan.pl](#vcf2h_scanpl)
* [vcf2map.pl](#vcf2mappl)

---


## vcf2baypass.pl

This script takes a vcf file and a corresponding population file, extracts the genotype information for each individual, groups the genotype information, and outputs a file that can be used in [BayPass](www1.montpellier.inra.fr/CBGP/software/baypass/files/BayPass_manual_2.1.pdf)

### Usage

`$ perl vcf2baypass.pl -vcf <yourFile.vcf> -pop <populationfile> -col_group <int> -outfile <yourOutfile>`

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

**Outfile:** Optional. File to print the results to. If no name is provided, the default is <name_of_vcf>.geno 

### Outputs

One file in the proper format for a BayPass scan. Each row in the file is a position, each column is an allele count for a particular group. More information can be found in the [BayPass Manual](www1.montpellier.inra.fr/CBGP/software/baypass/files/BayPass_manual_2.1.pdf)

The number of populations is also printed to standard out. BayPass will ask you for this number when you run the scan.



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

This script takes a vcf file and reformats the variant data into a .map file for use in [hapflk](https://forge-dga.jouy.inra.fr/projects/hapflk/wiki)

### Usage

`$ perl vcf2map.pl -vcf <yourFile.vcf> -outfile <yourOutfile>`

The -help option can be used to display usage infromation from the command line.

### Inputs

**VCF File:** Required. File to convert. Can be either phased or unphased data.

**Outfile:** Optional. File name to print the ouput to. Defaults to <name_of_vcf.map> if no name is provided.

### Outputs

One .map file for use in hapflk analysis. Each line is a variant and it contains the chromosome, the variant ID, and the bp coordinate. More information on the .map file format can 
be found in the [PLINK file format reference](https://www.cog-genomics.org/plink2/formats#map).



