#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use List::MoreUtils qw(zip);
use Data::Dumper qw(Dumper);

########################################################################
# 
# File   :  domAdd.pl
# History:  This program was written by Brian Ferolito   
#
########################################################################
#
# This program takes two MLM output files from TASSEL, a scanResults.txt,
# and the dataset version number from the command line. The scanData 
# file is read and two references to arrays are created containg causal
# and neutral loci. The base pair location is obtained for each of those
# arrays and those are stored in new arrays. The base 
#
########################################################################

my $scanFile;
my $sigTasselFile;
my $nonSigTasselFile;
my $version;
my $usage = "\n$0 [options] \n

Options:

-scanFile			File to open (Scan Results file Ex. 10900_Invers_ScanResults.txt)
-sigTasselFile		File to open (Significant Tassel MLM Ex. 10900.MLM.significant.txt)
-nonSigTasselFile	File to open (Non Significant Tassel MLM Ex. 10900.MLM.not_significant.txt)
-version			Dataset Number (10900)
-help				Show this message

";

GetOptions(

	'scanFile=s'			=>\$scanFile,
	'sigTasselFile=s'		=>\$sigTasselFile,
	'nonSigTasselFile=s'	=>\$nonSigTasselFile,
	'version=s'				=>\$version,
	help					=> sub {pod2usage($usage); },
	
	) or die($usage);

unless ($scanFile){
	die "Provide a file name to open, -scanFile <*_Invers_ScanResults.txt>\n " , $usage;
}	

unless ($sigTasselFile){
	die "Provide a file name to open, -sigTasselFile <*.MLM.significant.txt>\n " , $usage;
}

unless ($nonSigTasselFile){
	die "Provide a file name to open, -tasselFile <*.MLM.not_significant.txt>\n " , $usage;
}

unless ($version){
	die "Provide a version, -version <10900>\n ", $usage;
}	

########################################################################
#Outfiles

my $tp_out = join('', $version, '.domAdd.TP.txt');
my $fn_out = join('', $version, '.domAdd.FN.txt');
my $fp_out = join('', $version, '.domAdd.FP.txt');
my $tn_out = join('', $version, '.domAdd.TN.txt');

my $tpFh   = getFh('>', $tp_out);
my $fnFh   = getFh('>', $fn_out);
my $fpFh   = getFh('>', $fp_out);
my $tnFh   = getFh('>', $tn_out);

########################################################################

my $scanFh    							= getFh('<', $scanFile);
my $sigTasselFh  						= getFh('<', $sigTasselFile);
my $nonSigTasselFh						= getFh('<', $nonSigTasselFile);
my ($causalScanData, $neutralScanData)  = getScanData2Array($scanFh);

my @causalScanData  = @$causalScanData;
my @neutralScanData = @$neutralScanData;

my @causalBpArray   = getBParray(@causalScanData);
my @neutralBpArray	= getBParray(@neutralScanData);


my @tp_matchedData 	= matchTassel2Scan($sigTasselFh,    \@causalScanData,  \@causalBpArray);
my @fn_matchedData	= matchTassel2Scan($nonSigTasselFh, \@causalScanData,  \@causalBpArray);
my @fp_matchedData	= matchTassel2Scan($sigTasselFh,    \@neutralScanData, \@neutralBpArray);
my @tn_matchedData	= matchTassel2Scan($nonSigTasselFh, \@neutralScanData, \@neutralBpArray);


my @tp_finalArray 	= processFinalArray(@tp_matchedData);
my @fn_finalArray	= processFinalArray(@fn_matchedData);
my @fp_finalArray	= processFinalArray(@fp_matchedData);
my @tn_finalArray	= processFinalArray(@tn_matchedData);


print2File($tpFh, \@tp_finalArray);
print2File($fnFh, \@fn_finalArray);
print2File($fpFh, \@fp_finalArray);
print2File($tnFh, \@tn_finalArray);


########################################################################
# The following subroutine that returns the bp position, additive, and 
# dominance effect of the Tassel output file

sub _tassel {
	my ($tasselFh) = @_;
	my @effectsStore;
	while(<$tasselFh>){
		chomp $_;
		my $char = substr($_, 0, 5);
		if ( ! ($char eq "Trait")){
			my @line = split(" ", $_);
			my $domEffect = $line[10];
			my $addEffect = $line[7];
			my $pos = $line[3];
			
			my @effects = join("\t", $pos, $addEffect, $domEffect);
			push (@effectsStore, @effects)
		}
	}
	return @effectsStore;
}

###################################################################################
# The following subroutine takes two arguments. The first is whether it is a read or
# write operator. The second is the file name to be either opened or written to. A
# file handle is returned

sub getFh {
	my ($readOrwrite, $file) = @_;
	if($readOrwrite eq '<'){
		my $inFh;
		unless (open($inFh, '<', $file)){
			die "Unable to open $file for reading", $!;
		}
		return $inFh;
	}
	elsif($readOrwrite eq '>'){
		my $outFh;
		unless(open($outFh, '>', $file)){
			die "Unable to open $file for writing", $!;
		} 
		return $outFh;
	}
	else{ 
		die "This is not a read or write operator";
	}
}

###################################################################################

sub getScanData2Array{
	my ($scanFh) = @_;
	my @causalScanData;
	my @neutralScanData;
	while(<$scanFh>){
		chomp $_;
		my @line = split(" ", $_);
		my $position = $line[1];
		my $muttype = $line[4];
		$muttype =~ tr/"//d; #eliminate quotation marks to make life easier later
		my $selfCoef = $line[30];
		my $dom = 0;
	
		if($muttype eq "MT=2"){
			my @causalTabLine = join("\t", $position, $muttype, $selfCoef, $dom);
			push (@causalScanData, @causalTabLine);
		}elsif($muttype eq "MT=1"){
			my @neutralTabLine = join("\t", $position, $muttype, $selfCoef, $dom);
			push (@neutralScanData, @neutralTabLine);
		}else{
			next;
		}
	}
	return (\@causalScanData, \@neutralScanData);
}

###################################################################################

sub getBParray{
	my @scanData = @_;
	my @bpArray;
	foreach(@scanData){
		chomp $_;
		my @line = split(" ", $_);
		push (@bpArray, $line[0])
	}
	return @bpArray;
}

###################################################################################

#Matches the base pair positions of both data sets, both observed and expected.
#Adds the expected additive effect and the expected dominance effect to the observed 
#data if there is a match.

sub matchTassel2Scan{
	
	my ($tasselFh, $scanDataRef, $bpArrayRef) = @_;
	my $length_bpArray = scalar @$bpArrayRef;
	my @scanData       = @$scanDataRef;
	my @bpArray        = @$bpArrayRef;
	my @tasselData = _tassel($tasselFh);
	
	
	for(my $i = 0; $i <= $length_bpArray-1; $i++){
		foreach(@tasselData){
			chomp $_;
			my @line = split(" ", $_);
			if($line[0] eq $bpArray[$i]){
						
				my $finalLine = $scanData[$i];
				my @finalLineArray = split(" ", $finalLine);
			
				if(! ($line[1] eq 'NaN' | $line[2] eq 'NaN')){
					push (@finalLineArray, $line[1]);
					push (@finalLineArray, $line[2]);
					$finalLine = join("\t", @finalLineArray);
					$scanData[$i] = $finalLine;
				}
			}
		}
	}
	return @scanData;
}

###################################################################################

sub processFinalArray{
	my @matchedData = @_;
	my @finalArray;
	foreach(@matchedData){
		chomp $_;
		my @line = split(" ", $_);
		my $lineNumber = scalar @line;
		if($lineNumber eq 6){
			my $tabLine = join("\t", @line);
			push (@finalArray, $tabLine);
		}
	}
	return @finalArray;
}

###################################################################################

sub print2File{
	my ($outFh, $finalArrayRef) = @_;
	say $outFh join("\t", "basePairPosition", "expectedAdditive", "expectedDominance", "tasselAdditive", "tasselDominance");

	foreach (@$finalArrayRef){
		chomp $_;
		my @line = split(" ", $_);
		my $MTremoved = join("\t", $line[0], $line[2], $line[3], $line[4], $line[5]);
		say $outFh $MTremoved;
	}
}

###################################################################################

close $sigTasselFh;
close $nonSigTasselFh;
close $scanFh;