#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use List::Util qw(min max);

my $inFile;
my $outFile;
my $popFile;
my $colNum;
my $loci;
my $usage = "\n$0 [options] \n

Options:

-infile		File to open (VCF file)
-popFile	Corresponding population file
-outfile	Name of file to write to
-colNum		Column number that specifies the subgroup the individual belongs to
-help		Show this message

";

GetOptions(

	'infile=s'		=>\$inFile,
	'outfile=s'		=>\$outFile,
	'popFile=s'		=>\$popFile,
	'colNum=i'		=>\$colNum,
	help			=> sub {pod2usage($usage); },
	
	) or die($usage);
	
unless ($inFile){
	die "Provide a file name to open, -infile <infile.vcf>\n " , $usage;
}	
	
unless ($popFile){
	die "Provide a population file that corresponds with the VCF file, - popFile <indFILT.txt>\n ", $usage;
}

unless ($colNum){
	die "Please provide the column number in the population file that corresponds to the subpopulation group"
}

my $inFh;
unless (open($inFh, '<', $inFile)){
	die "Unable to open $inFile for reading", $!;
}

my $popFh;
	unless (open($popFh, '<', $popFile)){
	die "Unable to open $popFile for reading ", $!;
}

unless ($outFile){
	$outFile = $inFile.".bayescan";
}

my $outfh;
unless (open($outfh, '>', $outFile)){
	die "Can't open $outFile for writing", $!;
}

##############################################################
#Organizes subpopulations into a hash

my %sub_pop;
my $individual = 0;

while(<$popFh>){
	chomp $_;
	my $char = substr($_, 1, 2);
	if (! ($char eq "id")){
		my @line = split(" ", $_);
		my $group = $line[$colNum];
		if(defined $sub_pop{$group}){
			$sub_pop{$group} = join(" ", $sub_pop{$group}, $individual)
		}
		else{
			$sub_pop{$group} = $individual;
		}
    	$individual++; 
	}	
}
	
close $popFh;

##############################################################

my $subPopNum = keys %sub_pop;
my $popNumber = 1;
my @file = <$inFh>;
chomp @file;

my $loci_number = _getLociNumber(@file);
say "[loci]=$loci_number\n";

my $population = keys %sub_pop;
say "[populations]=$population";

#Iterate through every locus for each subpopulation 
foreach my $subgroup (sort { $a <=> $b } keys %sub_pop){
	
	say "\n[pop]=$popNumber";
	
	#store the individuals in the given subpopulation into an array
	my $sub_indi        = $sub_pop{$subgroup};
	my @sub_indiArray   =	split(" ", $sub_indi);
	my $sub_indi_length = @sub_indiArray;
	my $gene_number = $sub_indi_length * 2;
	my @vcf_data;
	my $allele_counter;
	
	foreach (@file){
		chomp $_;
		
		
		my $char = substr($_, 0, 1);
		if (! ($char eq '#')){
			
			$allele_counter++;
			@vcf_data = split/\t/, $_;
			
			my @snpArray;
			my $ref_count = 0;
			my $alt_count = 0;
						
			foreach (@sub_indiArray){
				
				foreach my $data (@vcf_data){
					
					#store the SNP information into an array
					my $chara = substr($data, 1, 1);
					if($chara eq '|'){
						push @snpArray, $data;
					}		
				}
					
					if ($snpArray[$_] eq "0|0"){
						$ref_count = $ref_count + 2;					
					}
					elsif ($snpArray[$_] eq "0|1" || "1|0"){
						$ref_count++;
						$alt_count++;
					}
					elsif ($snpArray[$_] eq "1|1"){
						$alt_count = $alt_count + 2;
					}
			}
			say join("\t",$allele_counter, $gene_number, "2", $ref_count, $alt_count);
		}
	
	}
$allele_counter++;				
$popNumber++;
}

#This subroutine obtains the number of locations that are being observed
sub _getLociNumber{
	my (@file) = @_;
	
	my $loci_number=0;
	foreach (@file){
		my $char = substr($_, 0, 1);
		if (! ($char eq '#')){
			$loci_number++;
		}
	}
	return $loci_number;
}		
