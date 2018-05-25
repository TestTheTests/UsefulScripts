#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;

my $posFile;
my $fstFile;

my $usage = "\n$0 [options] \n

Options:

-posFile		File to open containing the base pair position
-fstFile		The file containing the fst value
-help			Show this message

";

GetOptions(

	'posFile=s'		=>\$posFile,
	'fstFile=s'		=>\$fstFile,
	help			=> sub {pod2usage($usage); },
	
	) or die($usage);
	
unless ($posFile){
	die "Provide a file name to open, -posFile \n " , $usage;
}	

unless ($fstFile){
	die "Provide a file name to open, -fstFile \n " , $usage;
}	

my $posFh;
unless (open($posFh, '<', $posFile)){
	die "Unable to open $posFile for reading", $!;
}

my $fstFh;
	unless (open($fstFh, '<', $fstFile)){
	die "Unable to open $fstFile for reading ", $!;
}

my @vcf_file = <$posFh>;
chomp @vcf_file;
my @positionArray;

my @fst_file = <$fstFh>;
chomp @fst_file;
my @fstValue;
my @alphaValue;
my @logValue;
my @postProb;

######################################################
#Store the base pair position of each loci in an array

foreach (@vcf_file){
	my $char = substr($_, 0, 1);
	if (! ($char eq '#')){
		my @vcf_data = split/\t/, $_;
		push @positionArray, $vcf_data[1];
	}
}

######################################################
#Store the fst value for each value in an array

foreach (@fst_file){
	my @fst_data = split(" ", $_);
	push @fstValue, $fst_data[4];
	
}

#####################################################
#Store the log post odds in an array

foreach (@fst_file){
	my @fst_data = split(" ", $_);
	push @logValue, $fst_data[2];
}	

######################################################
#Store the posterior probability in an array

foreach (@fst_file){
	my @fst_data = split(" ", $_);
	push @postProb, $fst_data[1];
}

######################################################
#Store the alpha value in an array

foreach (@fst_file){
	my @fst_data = split(" ", $_);
	push @alphaValue, $fst_data[3];
	
}


for (my $i = 0; $i<7265; $i++){
	say join("\t", $i, $positionArray[$i], $fstValue[$i], $alphaValue[$i], $logValue[$i], $postProb[$i] );
}


	
