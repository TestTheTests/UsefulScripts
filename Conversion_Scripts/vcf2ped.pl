#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Scalar::Util qw(looks_like_number);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw(Dumper);
use File::Basename;



######################################################################################
#
# File	  : vcf2ped.pl
# History : 6/1/2018 Created by Kevin Freeman(KF)
#
#######################################################################################
#
# This script takes a vcf file and a corresponding population (.txt) file and combines
# and reformats the information, outputting a .ped file that can be used in hapflk
# analysis
#
#######################################################################################

my ($vcf, $popFile); 
my ($inFinal, $colEnv, $colPheno, $colGroup);
my $fastphase = 0;
my ($outfile);

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options: 

     -vcf		VCF to convert  (required)
     
     -population	Corresponding population file (required)
     
     -colGroup		Specify the column of the population file that your 
     			group data is in. 1st col is 0 (required)
     			
     -colEnv		Specify the column in the population file that your
     			environment data is in (optional)
     			
     -colPheno		Specify the column in the population file that your
     			phenotype data is in (optional)
     -colInFinal	Specify the column in the population file that tells you whether
     			an individual is in the final dataset, ie your VCF (optional)
     			
     -outfile		Output file prefix for .ped file (default: <name_of_vcf>)
     
     -fastphase		Should a fastPHASE file also be created to determine number of clusters K (default: FALSE)
     
     -help		Show this message

";

GetOptions(
   'vcf=s' => \$vcf,
   'population=s'	=> \$popFile,
   'colGroup=i' 	=> \$colGroup,
   'colEnv=i'		=> \$colEnv,
   'colPheno=i'		=> \$colPheno,
   'colInFinal=i'	=> \$inFinal,
   'outfile=s' 		=> \$outfile,
   'fastphase=s'	=> \$fastphase,
    help => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}
unless ($popFile) {
	die "\n-pop not defined\n$usage";
}
unless ($colGroup) {
	die "\n-col_group not defined\n$usage";
}

if ($fastphase =~ /^(true)|1$/i){
	$fastphase = 1;
}
elsif ($fastphase =~ /^(false)|0$/i){
	$fastphase = 0;
}
else {
	$fastphase = 0;
	warn "Unrecognized -fastphase option: $fastphase. A fastphase file will not be created";
}

############ Read pop file into a hash ################################################
say STDERR "\nReading pop file.....";

my $popFh;
unless (open ($popFh, "<", $popFile) ){
	die "can't open '$popFile', $!";
}

my %individualsHash;
my $individualNum = 1;				    # individualNum assigns an iid to each individual in order. Starts at 1 becaue
										# 0 is not a valid plink iid
										
while(<$popFh>){
    chomp $_;
    my @line = split(" ",$_);
    unless (looks_like_number $line[0]) { # make sure the program doesn't store the header
    	next;
    }
    
    # if $inFinal was specified, check if the individual is in the final dataset. If not, skip
    if (defined $inFinal){
    	my $in = $line[$inFinal];
    	unless($in eq "TRUE"){
    		next;
    	}
    }
    
    my $group = $line[$colGroup];
    
    if (int($group) != $group){
    	# make sure user gave the correct column number
    	die "Invalid group value: ",$group,", are you sure you selected the right column?";
    }
   
  	$individualsHash{$individualNum}{group}  = $group;
   
  	# add phenotypes if user gave column numbers, else phenotype = -9
  	if (defined $colPheno){
  		$individualsHash{$individualNum}{phenotype} = $line[$colPheno];
  	}
  	else {
  		$individualsHash{$individualNum}{phenotype} = -9;
  	}
   			
    $individualNum++;
}
# individualsHash is now a hash of hashes. The 'outer' hash has keys that correspond with
# the individual numbers and the inner, anonymous hash has keys that correspond with the type
# of data we want to access. It always has the key "group" to access all the groups of the individual.
# If the user defined them, it may also have keys for "phenotype" 

close $popFh;

############ Read VCF into an array ###################################################
say STDERR "Reading VCF.....";

my $vcfFh;
unless(open ($vcfFh, "<", $vcf)){
	die ("Could not open $vcf");
}

my @snpValArray = convertVCF($vcfFh);

close $vcfFh;

# snpValArray is now an array of strings. Each string corresponds to one snp. It contains
# a list of alleles for each individual. Inviduals are separated by spaces and alleles
# within an individual are separated by commas 


########### Put data into .ped format ###############################################

say STDERR "Converting.....";

## create outfile name if one was not given, open outfile
my $base = basename($vcf, ".vcf");
unless (defined $outfile){
	$outfile = join(".", $base, "ped");
}
my $outfh;
unless (open ($outfh, ">", $outfile)){
	die "Could not open $outfile $!";
}

# go through the hash in order, by individual
my @allAllelesByIndiv;                                   # array of arrays to store alleles grouped by individual
foreach my $individual (sort {$a <=> $b} keys %individualsHash ){
	my @allIndivAlleles;
	foreach my $snp (@snpValArray){  
		my $indivAllele  = $snp -> {$individual};	 	# access the value in the hash ref for the current individual
		$indivAllele =~ s/,/ /g;						# replace commas with spaces
		push @allIndivAlleles, $indivAllele;
	}

	say $outfh join(" ", $individualsHash{$individual}{group}, $individual, 
					0, 0, 0, $individualsHash{$individual}{phenotype}, @allIndivAlleles);
	push @allAllelesByIndiv, \@allIndivAlleles;
}

close $outfh;
say "Created $outfile.";

######### Create fastphase file if asked for

if ($fastphase){
	say "\nCreating fastPHASE file............................";
	createFastPhase(\@allAllelesByIndiv, \%individualsHash, $base);
}

################# SUBROUTINES ############################################################

#-----------------------------------------------------------------------
# void context = convertVcf($infh, $outfh);
#-----------------------------------------------------------------------
# This subroutine takes an infile handle and an outfile handle. It 
# takes the input vcf file, extracts the relevant data, and generates
# a line of alleles 
#-----------------------------------------------------------------------
sub convertVCF {
	my ($infh) = @_;
	
	my @allelesConverted;
	
	while (<$infh>){
		if ($_ =~ /^#/){			#skip header lines
			next;
		}
		my @line = split("\t",$_);
			
		my $refAllele = $line[3];
		my $altAllele = $line[4];
	
		my $translatedLine = _vcfLine2basesLine( { reference => $refAllele, 
											  	   alt       => $altAllele, 
											  	   line 	     => $_ } );
		push @allelesConverted, $translatedLine;
	}
	return @allelesConverted;
}

#-----------------------------------------------------------------------
# ($commaDelimitedString) = _vcfLine2basesLine({reference, alt, line});
#-----------------------------------------------------------------------
# This subroutine takes a line containing genotype information and 
# parameters to convert that information in the form of a referenced
# hash and converts them to a line that represents the info as bases.
# It returns a reference to a hash where the keys are individuals 
# and values are the phenotypes of those individuals at the given SNP
#-----------------------------------------------------------------------

sub _vcfLine2basesLine {
	my ($refArgs) = @_;
	my $line = $refArgs 	-> {line};
	my $ref = $refArgs 		-> {reference};
	my $alt = $refArgs 		-> {alt};
	
	my @gtArray    = $line =~ /[\d\.]\|[\d\.]/g;     # get only the genotype data
	my $basesLine  = join(" ", @gtArray);		    		 	
 	
	$basesLine =~ s/0/$ref/eg;					     # replace 0's with ref allele
	$basesLine =~ s/1/$alt/eg;					     # replace 1's with alt allele
	$basesLine =~ s/\|/,/g;						     # replace |'s with commas
	$basesLine =~ s/\./?/g;						     # replace missing data with 0
	
	my @vals = split(" ", $basesLine);
	my @indivs = (1..scalar @vals);					 # create a sequence from 1 to the length of the array	

	my %snpHash;									
	@snpHash{@indivs} = @vals;						 # create a hash where the keys are the individuals and values are genotypes
	return \%snpHash;								 # return referenced hash
}


#-----------------------------------------------------------------------
#  createFastPhase(\@alleles, \%individuals, $fileprefix);
#-----------------------------------------------------------------------
# Called in void context, this subroutine takes an array of alleles,
# a hash with information about individuals, and a file prefix and prints 
# the information to a .inp file that can be used in fastPHASE 
#-----------------------------------------------------------------------

sub createFastPhase {
	my ($alleleAoARef, $indivHashRef, $base) = @_;
	my $outfile = $base.".inp";                      # create outfile name
	
	my $outfh;										 # open outfile
	unless (open ($outfh, ">", $outfile)){
		die "Could not open $outfile $! for writing";
	}
	
	say $outfh scalar keys %$indivHashRef;           # say number of individuals
	say $outfh scalar @{$alleleAoARef -> [0]};		 # say number of alleles
	
	## loop through all individuals and print GT information
	my %indivHash = %$indivHashRef;
	foreach my $indiv (sort {$a <=> $b} keys %indivHash){
		say $outfh join(" ", "# ind", $indiv);
		my $indivAllelesRef = $alleleAoARef -> [$indiv];   # access alleles corresponding to the individual
		my @indivAlleles = @$indivAllelesRef;
		my @gt1;
		my @gt2;
		foreach my $gt (@indivAlleles){					   # go through all alele pairs and split them up
			push @gt1, substr $gt, 0, 1;
			push @gt2, substr $gt, 2, 1;
					
		}
		say $outfh join("", @gt1);
		say $outfh join("", @gt2);
	}		
	say "Created $outfile \n\n";
}
