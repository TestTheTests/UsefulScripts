#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;

######################################################################################
#
# File	  : vcf2H_scan.pl
# History : 2/9/2018 Created by Kevin Freeman(KF)
#
#######################################################################################
#
# This script takes a vcf file and processes it into a SNP file  that can be used
# in H-scan. It assumes that the given file contains PHASED genotype data
#
#######################################################################################

my $vcf;
my $outFile;

########### Command line options ######################################################

my $usage = "\nUsage: $0 [options]\n 
Options:
     -vcf		VCF to convert  (required -- genotype data must be phased)
     -outfile		Name of output file (default: <name_of_vcf>.hscan)
     -help		Show this message

";

GetOptions(
   'vcf=s' => \$vcf,
   'outfile=s' 		=> \$outFile,
    help => sub { pod2usage($usage); },
) or pod2usage(2);

unless ($vcf) {
    die "\n-vcf not defined\n$usage";
}

############  Read VCF #################################################################

### get file handles
my $infh;
unless (open($infh, '<', $vcf)){
	die "Unable to open $vcf for reading", $!;
}

unless ($outFile){
	$outFile = $vcf.".hscan";		# create default filename if one was not provided
}
my $outfh;
unless (open($outfh, '>', $outFile)){
	die "Can't open $outFile for writing", $!;
}

### Initialize lookup table
my %lookupTable= ('0' => undef,		# this will change to ref allele 				
			  	  '1' => undef,		# this will change to alt allele
			  	  '|' => ',',
			      '.' => 'N'		# missing data
);
### convert
convertVcf($infh, $outfh);
## give feedback and close files
close $outfh;
close $infh;
say "\nCreated ", $outFile;

#-----------------------------------------------------------------------
# void context = convertVcf($infh, $outfh);
#-----------------------------------------------------------------------
# This subroutine takes an infile handle and an outfile handle. It 
# takes the input vcf file, extracts the relevant data, and generates
# a hscan compatible file. It depends on the _vcfLine2HscanLine subroutine
#-----------------------------------------------------------------------
sub convertVcf{
	my ($inHandle, $outHandle) = @_;
	my $i = 0;
	while (<$infh>){
		if ($_ =~ /^#/){			#skip header lines
			next;
		}
		my @line = split("\t",$_);
			
		my $position  = $line[1];
		my $refAllele = $line[3];
		my $altAllele = $line[4];
	
		my $translatedLine = _vcfLine2HscanLine( { pos   	=> $position, 
											      reference => $refAllele, 
											  	  alt       => $altAllele, 
											  	  line 	     => $_ } );
		say $outHandle $translatedLine;
		$i++;
		if ($i % 2000 == 0) {say "Processed ".$i." variants"}; # give user feedback
			
	}
}

#-----------------------------------------------------------------------
# ($commaDelimitedString) = _vcfLine2HscanLine({pos, reference, alt, line});
#-----------------------------------------------------------------------
# This subroutine takes a line containing genotype information and 
# parameters to convert that information in the form of a referenced
# hash and converts them to a line that can be used with H-Scan
#-----------------------------------------------------------------------

sub _vcfLine2HscanLine {
	my ($refArgs) = @_;
	my $line = $refArgs 	-> {line};
	my $ref = $refArgs 		-> {reference};
	my $alt = $refArgs 		-> {alt};
	
	$lookupTable{'0'} = $ref;
	$lookupTable{'1'} = $alt;
	
	my @hscanLine = ($refArgs -> {pos});	    # intialize line array, starting with SNP position
	
	for ($line =~ /[\d\.]\|[\d\.]/g){
		$_ =~ s/(.)/defined($lookupTable{$1}) ? $lookupTable{$1} : $1/eg;
		push @hscanLine, $_;
	}
	return join(',', @hscanLine);
}
