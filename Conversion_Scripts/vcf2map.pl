#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use File::Basename;
use Pod::Usage;

######################################################################################
#
# File	  : vcf2map.pl
# History : 2/23/2018 Created by Kevin Freeman(KF)
#
#######################################################################################
#
# This script takes a vcf file and reformats the variant data into a .map file 
# so it can be used in hapflk
#  
#######################################################################################

my $vcf; 
my $outfile;

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options:
     -vcf		VCF to convert  (required)
     -outfile		file to print to (default = <name_of_vcf>.map
     -help		Show this message

";

GetOptions(
   'vcf=s'		 => \$vcf,
   'outfile=s' 	 => \$outfile,
    help 		 => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}

######################## Convert VCF ###################################

my $vcfBase = basename($vcf, ".vcf");
say $vcfBase;
unless (defined $outfile){
	$outfile = $vcfBase.".map";			# generate default outfile name based on given vcf
}

# get filehandles
my $infh;
unless (open($infh, '<', $vcf)){
	die "Could not open vcf for reading", $!;
}
my $outfh;
unless (open ($outfh,'>', $outfile)){
	die "Could not open  $outfile for reading ", $!;
};

# read and convert the file
vcf2map($infh, $outfh);

# close files and give user feedback
close $infh;
close $outfh;
say "Created ", $outfile;


#-----------------------------------------------------------------------
# void context = vcf2map($infh, $outfh);
#-----------------------------------------------------------------------
# This subroutine takes an infile handle and an outfile handle. It 
# takes the input vcf file, extracts the relevant data, and generates
# a .map file 
#-----------------------------------------------------------------------
sub vcf2map{
	my ($inHandle, $outHandle) = @_;
	my $i = 1;							# start at 1 because 0 is an invalid plink IID
	while (<$inHandle>){
		if ($_ =~ /^#/){				#skip the header lines
			next;
		}
		my @line  = split("\t", $_);
		my $chrom = $line[0];
		my $varID = $line[2];
		my $pos   = $line[1];
		
		if ($varID eq '.'){				# replace missing var id data with a unique number
			$varID = $i;
		}
		
		say $outHandle join("\t", $chrom,$varID,"0",$pos); # print to the .map file
		$i++;
	}
}
