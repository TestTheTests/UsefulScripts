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

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options:
     -vcf		VCF to convert  (required)
     -population	Corresponding population file (required)
     -outfile		Name of output file (default: <name_of_vcf>.geno)
     -help		Show this message

";

GetOptions(
   'vcf=s' => \$vcf,
   'population=s' => \$popFile,
   'outfile=s' => \$outFile,
    help => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}
unless ($popFile) {
	die "\n-pop not defined\n$usage";
}

############ Read pop file into a hash ################################################
say "\nReading pop file.....";

my $popFh;
unless (open ($popFh, "<", $popFile) ){
	die "can't open '$popFile', $!";
}

my %groupsHash;
while(<$popFh>){
    chomp $_;
    my @line = split(" ",$_);
    my $id = $line[0];
    unless (looks_like_number($id)) { # make sure the program doesn't store the header
    	next;
    }
    my $group = $line[5];
    if ($groupsHash{$group}){		  # check if group matches a previously read group
   		$groupsHash{$group} = join(" ",$groupsHash{$group}, $id);
    }
    else {
    	$groupsHash{$group} = $id;
    }
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
		my $snpValsString = join(" ","0|0", @snpVals); # Need to edit: adds on extra data value because 999 GT were in											   
		push @snpValArray, $snpValsString;	 		   # vcf test file but 1000 individuals in pop file
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
	$baypass = $baypass.$alleles."\n";
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

	foreach my $group (sort { $a <=> $b } keys %groupsHash){
		my $individuals = $groupsHash{$group};					# find all individuals in the group
		my @individuals = split(" ", $individuals);				# make individuals into arrary
		my $groupVals = join(" ",@snpValsArray[@individuals]);	# find values by index
		my ($allele1, $allele2) = countAlleles($groupVals);
		$alleleString = $alleleString.$allele1." ".$allele2." ";
	}
	return $alleleString;
}
#say "calc alleles: ", calcAlleles($snpValArray[0], \%groupsHash);
#my $deref = $snpValArray[0];
#say "deref: ", @$deref;
#-----------------------------------------------------------------------
# ($count1, $count2) = countAlleles(@values);
#-----------------------------------------------------------------------
# This function takes an array where each element in the array is 
# vcf data in the form "0|1" and it counts the total number of alleles
# of each type
#-----------------------------------------------------------------------
my $i = 0;
sub countAlleles{
	my ($groupVals) = @_;
	my $count1 = () = $groupVals =~ /0/g;		# find number of matches of '0'
	my $count2 = () = $groupVals =~ /1/g;
	return ($count1, $count2);
}



