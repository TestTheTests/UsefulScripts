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

my $infh;
unless (open($infh, '<', $vcf)){
	die "Unable to open $vcf for reading", $!;
}

### Initialize lookup table
my %lookupTable= ('0' => undef,		# this will change to ref allele 				
			  	  '1' => undef,		# this will change to alt allele
			  	  '|' => ',',
			      '.' => 'N'		# missing data
);
my @allHscanLines;
while (<$infh>){
	my @line;
	if ($_ !~ /^#/){
		@line = split("\t",$_);
	}			
	else {													# skip any header line
		next;
	}
	my $position = $line[1];
	my $refAllele = $line[3];
	my $altAllele = $line[4];
	
	my $translatedLine = vcfLine2HscanLine( { pos   => $position,  reference => $refAllele, 
											  alt   => $altAllele, line 	 => $_ } );
	push @allHscanLines, $translatedLine;
	if (scalar @allHscanLines %1000 == 0){					# give user feedback
		say "processed ",scalar @allHscanLines, " lines";
	}
}
close $infh;

########## Print to file ################################################################

unless ($outFile){
	$outFile = $vcf.".hscan";		# create default filename if one was not provided
}
my $outfh;
unless (open($outfh, '>', $outFile)){
	die "Can't open $outFile for writing", $!;
}

print $outfh join("\n", @allHscanLines);
close $outfh;
say "\nCreated ", $outFile;

#-----------------------------------------------------------------------
# ($commaDelimitedString) = vcfLine2HscanLine({pos, reference, alt, line});
#-----------------------------------------------------------------------
# This subroutine takes a line containing genotype information and 
# parameters to convert that information in the form of a referenced
# hash and converts them to a line that can be used with H-Scan
#-----------------------------------------------------------------------

sub vcfLine2HscanLine {
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
