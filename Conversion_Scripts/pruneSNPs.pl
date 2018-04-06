#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

######################################################################################
#
# File	  : pruneSnps.pl
# History : 4/6/2018 Created by Kevin Freeman(KF)
#
#######################################################################################
#
# This script takes a vcf file and a file containing scan results and returns a vcf
# with only the quasi-independent alleles. It also generates a tab-delimited file 
# giving the indexes of the quasi-independent alleles
#
#######################################################################################

my $vcf;
my $scanResults;
my $outFile;
my $posCol = 0;
my $chrCol = 1;
my $indCol = 3;

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options:
     -vcf		VCF to prune  (required)
     -scan		File with scan results (required)
     -posCol	Column of the scan file that contains the SNP position (default = 0)
     -chrCol	Column of the scan file that contains the chromosome number (0-based, default = 1) 
     -indCol	Column of the scan file that indicates whether the SNP is
     			quasi-independent (0-based, default = 3)
     -outfile		Name of output file (default: <name_of_vcf>.pruned.vcf)
     -help		Show this message

";

GetOptions(
   'vcf=s' 			=> \$vcf,
   'scan=s' 		=> \$scanResults,
   'chrCol=i'		=> \$chrCol,
   'posCol=i' 		=> \$posCol,
   'indCol=i' 		=> \$indCol, 
   'outfile=s' 		=> \$outFile,
    help => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}
unless ($scanResults) {
	die "\n-scan not defined\n$usage";
}

######## Read in Scan Results ####################################################
my $scanFh;
unless (open($scanFh, '<', $scanResults)){
	die "Could not open scan file for reading $!";
}
my $first = 1;
my %posHash;
while (<$scanFh>){
	if ($first){    # skip header line
		$first = 0;
		next;
	}
	chomp $_;
	my @line = split(/\s/, $_); # split on whitespace
	my ($chr,$pos,$ind) = @line[$chrCol, $posCol, $indCol];
	
	# combine chr and pos into one key for the hash that maps to the 
	# independence 
	# ex : 1.37685 => "TRUE"
	#     chr pos       ind
	$chr =~ s/"//g;
	my $key = join(".", $chr,$pos); 
	$posHash{$key} = $ind;
}

###### Read in VCF, check lines, print ###########################################

unless (defined $outFile){
	my $noExt = $vcf;
	$noExt =~ s/\.vcf$//;    # remove .vcf from the end of the vcf file name
	$outFile = join(".", $noExt, "pruned", "vcf");
}

my $inVCFfh;
unless (open($inVCFfh, '<', $vcf)){
	die "Can't open VCF file for reading $!";
}
my $outFh;
unless (open($outFh, '>', $outFile)){
	die "Can't open outfile for writing $!";
}
my $indexesOutFh;
my $indexFile = "indexes_remaining.txt";
unless (open ($indexesOutFh, '>', $indexFile)){
	die "Can't open indexes outfile for writing $!";
}

my $i = 0;
while (<$inVCFfh>){
	chomp $_;
	if ($_ =~ /^#/){        # print all header lines automatically
		 $_ =~ s/\ti\d+//g; # remove individual numbers from header (many will be
		 say $outFh $_;     # pruned, no longer accurate)
		 next;
	} 
	my @line = split("\t", $_);
	
	my ($chr, $pos) = @line[0,1];
	my $key = join(".", $chr, $pos);
	
	if (defined $posHash{$key} and $posHash{$key} eq "TRUE"){
		say $outFh $_;
		print $indexesOutFh $i."\t"; 
	}
	$i++;
}

close $outFh;
close $inVCFfh;

say "\nCreated $outFile";
say "Created $indexFile\n";
