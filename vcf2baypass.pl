#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Scalar::Util qw(looks_like_number);
use Getopt::Long;
use Pod::Usage;

######################################################################################
#
# File	  : vcf2baypass.pl
# History : 2/2/2018 Created by Kevin Freeman(KF)
#
#######################################################################################
#
# This script takes a vcf file and a corresponding population file, extracts the
# genotype information for each individual, groups the genotype informatiion,
#  and outputs a file in a format that can be used in BayPass
#
#######################################################################################

my $vcf; 
my $popFile; 
my $outFile;
my $col;

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options:
     -vcf		VCF to convert  (required)
     -population	Corresponding population file (required)
     -col_group		specify the column of the population file that your 
     				group data is in. 1st col is 0 (required)
     -outfile		Name of output file (default: <name_of_vcf>.geno)
     -help		Show this message

";

GetOptions(
   'vcf=s' => \$vcf,
   'population=s'	=> \$popFile,
   'col_group=i' 	=> \$col,
   'outfile=s' 		=> \$outFile,
    help => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}
unless ($popFile) {
	die "\n-pop not defined\n$usage";
}
unless ($col) {
	die "\n-col_group not defined\n$usage";
}

############ Read pop file into a hash ################################################
say "\nReading pop file.....";

my $popFh;
unless (open ($popFh, "<", $popFile) ){
	die "can't open '$popFile', $!";
}

my %groupsHash;
my $individualNum = 0;				    # individualNum tells us what line we are on. 0 = first line
										# AFTER the header
while(<$popFh>){
    chomp $_;
    my @line = split(" ",$_);
    unless (looks_like_number $line[0]) { # make sure the program doesn't store the header
    	next;
    }
    my $group = $line[$col];
    if (int($group) != $group){
    	# make sure user gave the correct column number
    	die "Invalid group value: ",$group,", are you sure you selected the right column?";
    }
    if ($groupsHash{$group}){		  # check if group matches a previously read group
   		$groupsHash{$group} = join(" ",$groupsHash{$group}, $individualNum);
    }
    else {
    	$groupsHash{$group} = $individualNum;
    }
    $individualNum++;
}
# groupsHash now contains keys corresponding to each group in the population and values
# that are space separated strings containing id #s of each individual in the group

close $popFh;
############ Read VCF into an array ###################################################
say "Reading VCF.....";

my $vcfFh;
unless (open ($vcfFh, "<", $vcf) ){
    die "cant open '$vcf', $!";
}

my @snpValArray;
while(<$vcfFh>){
	if ($_ =~ /[\d\.][\|\/][\d\.]/){				   # regex matches: 1|0 OR 1/0 OR .|. OR ./.
		my @snpVals = $_ =~ /[\d\.][\|\/][\d\.]/g;     # create array containing all matches
		my $snpValsString = join(" ", @snpVals); 
		push @snpValArray, $snpValsString;
	}
}
# snpValArray is now an array of strings. Each string is a space separated list of allele
# counts for one snp

close $vcfFh;

########### Put data into baypass format ###############################################

say "Converting.....";
my $baypass = "";
foreach my $snp (@snpValArray){
	my $alleles = calcAlleles($snp, \%groupsHash);
	$baypass = join("",$baypass,$alleles,"\n");
}

unless ($outFile){
	$outFile = $vcf.".geno";
}
open (my $outFh, '>', $outFile);
print $outFh $baypass;
close $outFh;

my $ngroups = keys(%groupsHash);
say "\nCreated ", $outFile;
say "\nNumber of populations = ", $ngroups;

#-----------------------------------------------------------------------
# $alleleString = calcAlleles( $refArray, $refHash);
#-----------------------------------------------------------------------
# This function takes a referenced array and a referenced hash. The 
# array is ordered vcf data for one snp and the hash tells which 
# individual belongs to each group. Returns a string representing 
# population grouped counts for the snp
#-----------------------------------------------------------------------
sub calcAlleles{
	my ($snpVals, $groupsHashRef) = (@_);
	my %groupsHash = %$groupsHashRef;
	my @snpValsArray = split(" ", $snpVals);
	my $alleleString = "";
	unless (scalar @snpValsArray == $individualNum){
		die "VCF data does not match population data, different number of
		individuals", $!;
	}

	foreach my $group (sort { $a <=> $b } keys %groupsHash){
		my @individuals = split (" ", $groupsHash{$group});					# find all individuals in the group
		my $groupVals = join(" ",@snpValsArray[@individuals]);	# find values by index
		my ($allele1, $allele2) = countAlleles($groupVals);
		$alleleString = join(" ",$alleleString,$allele1,$allele2);
	}
	return substr $alleleString, 1;
}
#say "calc alleles: ", calcAlleles($snpValArray[0], \%groupsHash);
#my $deref = $snpValArray[0];
#say "deref: ", @$deref;
#-----------------------------------------------------------------------
# ($count1, $count2) = countAlleles(@values);
#-----------------------------------------------------------------------
# This function takes a string with space delimited vcf data in the form 
# "0|1" and it counts the total number of alleles  of each type
#-----------------------------------------------------------------------
sub countAlleles{
	my ($groupVals) = @_;
	my $count1 = () = $groupVals =~ /0/g;		# find number of matches of '0'
	my $count2 = () = $groupVals =~ /1/g;
	return ($count1, $count2);
}



