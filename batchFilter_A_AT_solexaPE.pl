#!/usr/bin/perl -w

use warnings;
use strict;
use Getopt::Std;
use Getopt::Long;

###############################################################
# input options
my $usage = qq(
Usage:      batchFilter_A_AT_solexaPE.pl Parameters

Parameters: solexaReadsPE_NO1                 Counterpart 1 of Solexa PE reads sequence file in fastq format. (file)
            solexaReadsPE_NO2                 Counterpart 2 of Solexa PE reads sequence file in fastq format. (file)
            adapterSequence                   Adapter sequence file in fasta format. (file)
            blastresult1                      result of blasting adapter1 and 2 against counterpart 1 of soelxa PE reads using ncbi blastn in m9 format. (file)
            blastresult2                      result of blasting adapter1 and 2 against counterpart 2 of soelxa PE reads using ncbi blastn in m9 format. (file)
            filenamePrefix                    Prefix for the file name of output. (string)
            thresholdOfConsecutiveA           Threshold for the number of consecutive N in a read. Default: 15. (number)
            o                                 directory of output.(directory of file system)

Example:    batchFilter_A_AT_solexaPE.pl -solexaReadsPE_NO1 s_1_1_sequence.txt -solexaReadsPE_NO2 s_1_2_sequence.txt -adapterSequence adapterSequence.txt -blastresult1 blastresult1 -blastresult2 blastresult2 -filenamePrefix s_1 -readLength 36 -thresholdofConsecutiveA 5 -o /home/gene/escience/tmp/
\n);

my $solexaReads1 = "";
my $solexaReads2 = "";
my $adapterSeq = "";
my $blastresult1 = "";
my $blastresult2 = "";
my $prefix = "";
my $thresholdOfConsecutiveA = 15;
my $o = "";

&GetOptions
(
 "solexaReadsPE_NO1:s" => \$solexaReads1,
 "solexaReadsPE_NO2:s" => \$solexaReads2,
 "adapterSequence:s" => \$adapterSeq,
 "blastresult1:s" => \$blastresult1,
 "blastresult2:s" => \$blastresult2,
 "filenamePrefix:s" => \$prefix,
 "thresholdOfConsecutiveA:s" => \$thresholdOfConsecutiveA,
 "o:s" => \$o,
);

die($usage) if ($solexaReads1 eq "" || $solexaReads2 eq "" || $adapterSeq eq "" || $blastresult1 eq "" || $blastresult2 eq "" || $prefix eq "" || $thresholdOfConsecutiveA eq "" || $o eq "");

###############################################################
# get adapter label
open INadapterseq, "$adapterSeq" or die "$!";
my $adapterLabel1;
my $adapterLabel2;
my $adapterID = 1;
while (<INadapterseq>){
	chomp;
	if (/^>(\S+)/){
		if ($adapterID == 1){
			$adapterLabel1 = $1;
			$adapterID++;
		}else{
			$adapterLabel2 = $1;
		}
	}
}

###############################################################
# getBlastResult
open INBLAST1, "$blastresult1" or die "$!";
my %hashINBLAST1;
while(<INBLAST1>){
	chomp;
	if(!/^#/){
		my @parts = split /\t/;
		$hashINBLAST1{$parts[1]} = $parts[0];
	}
}
close INBLAST1;

open INBLAST2, "$blastresult2" or die "$!";
my %hashINBLAST2;
while (<INBLAST2>){
	chomp;
	if (!/^#/){
		my @parts = split /\t/;
		$hashINBLAST2{$parts[1]} = $parts[0];
	}
}
close INBLAST2;

###############################################################
# loop through each read
print "loop through each read......";
my $outputNamePreservedPE1 = $prefix."_preserved1";
my $outputNamePreservedPE2 = $prefix."_preserved2";
my $outputNameSingle = $prefix."_single";
my $outputNameTrashA = $prefix."_trashConsecutiveA";
my $outputNameTrashAdapter = $prefix."_trashAdapter";
my $outputPathNamePreservedPE1 = $o.$outputNamePreservedPE1;
my $outputPathNamePreservedPE2 = $o.$outputNamePreservedPE2;
my $outputPathNameSingle = $o.$outputNameSingle;
my $outputPathNameTrashA = $o.$outputNameTrashA;
my $outputPathNameTrashAdapter = $o.$outputNameTrashAdapter;
open OUTpreservedPE1, ">>$outputPathNamePreservedPE1" or die "$!";
open OUTpreservedPE2, ">>$outputPathNamePreservedPE2" or die "$!";
open OUTsingle, ">>$outputPathNameSingle" or die "$!";
open OUTtrashConsecutiveA, ">>$outputPathNameTrashA" or die "$!";
open OUTtrashAT, ">>$outputPathNameTrashAdapter" or die "$!";
open INsolexaReads1, "$solexaReads1" or die "$!";
open INsolexaReads2, "$solexaReads2" or die "$!";

my ($inputLinePE1, $inputLinePE2, $line1PE1, $line2PE1, $line3PE1, $line4PE1, $line1PE2, $line2PE2, $line3PE2, $line4PE2);
my $countReads4lines  = 1;
my $offsetPE1 = 0;
my $offsetPE2 = 0;
my (@distributionNumPE1, @distributionNumPE2, @distributionPositionPE1, @distributionPositionPE2);
my $countAdapter1PE1 = 0;
my $countAdapter2PE1 = 0;
my $countAdapter1PE2 = 0;
my $countAdapter2PE2 = 0;
my $countReads = 0;
my $countConsecutiveAreadsPE1 = 0;
my $countConsecutiveAreadsPE2 = 0;
my ($polyA_PE1, $polyA_PE2, $locPE1, $locPE2);
my $readlength = `tail -1 $solexaReads1 | awk '{ print length }'`;
chomp $readlength;

for ( my $i = 0 ; $i < $readlength ; $i++ ) {
	$distributionNumPE1[$i]      = 0;
	$distributionPositionPE1[$i] = 0;
	$distributionNumPE2[$i]      = 0;
	$distributionPositionPE2[$i] = 0;
}
push @distributionNumPE1,0;
push @distributionNumPE2,0;
while (defined($inputLinePE1 = <INsolexaReads1>)) {
	$inputLinePE2 = <INsolexaReads2>;
	chomp $inputLinePE1;
	chomp $inputLinePE2;
	if ( $countReads4lines == 1 ) {
		$line1PE1 = $inputLinePE1;
		$line1PE2 = $inputLinePE2;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 2 ) {
		$line2PE1 = $inputLinePE1;
		$line2PE2 = $inputLinePE2;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 3 ) {
		$line3PE1 = $inputLinePE1;
		$line3PE2 = $inputLinePE2;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 4 ) {
		$line4PE1 = $inputLinePE1;
		$line4PE2 = $inputLinePE2;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	$countReads4lines = 1;
	$countReads++;
	$polyA_PE1 = ( $line2PE1 =~ tr/A// );
	$polyA_PE2 = ( $line2PE2 =~ tr/A// );
	$distributionNumPE1[$polyA_PE1]++;
	$distributionNumPE2[$polyA_PE2]++;
	$locPE1 = index $line2PE1, 'A', $offsetPE1;
	while ($locPE1 != -1){
		$distributionPositionPE1[$locPE1]++;
		$offsetPE1 = $locPE1 + 1;
		$locPE1 = index $line2PE1, 'A', $offsetPE1;
	}
	$locPE2 = index $line2PE2, 'A', $offsetPE2;
	while ($locPE2 != -1){
		$distributionPositionPE2[$locPE2]++;
		$offsetPE2 = $locPE2 + 1;
		$locPE2 = index $line2PE2, 'A', $offsetPE2;
	}
	$offsetPE1 = 0;
	$offsetPE2 = 0;
	my ($readid1) = ($line1PE1 =~ /^@(\S+)/);
	my ($readid2) = ($line1PE2 =~ /^@(\S+)/);
	if ((($line2PE1 =~ /A{$thresholdOfConsecutiveA,}/) || (exists $hashINBLAST1{$readid1})) && (($line2PE2 =~/A{$thresholdOfConsecutiveA,}/) || (exists $hashINBLAST2{$readid2}))){
		if (exists $hashINBLAST1{$readid1}){
			print OUTtrashAT "$line1PE1\n";
			print OUTtrashAT "$line2PE1\n";
			print OUTtrashAT "$line3PE1\n";
			print OUTtrashAT "$line4PE1\n";
			if ($hashINBLAST1{$readid1} eq $adapterLabel1){
				$countAdapter1PE1++;
			}elsif($hashINBLAST1{$readid1} eq $adapterLabel2){
				$countAdapter2PE1++;
			}
		}else{
			$countConsecutiveAreadsPE1++;
			print OUTtrashConsecutiveA "$line1PE1\n";
			print OUTtrashConsecutiveA "$line2PE1\n";
			print OUTtrashConsecutiveA "$line3PE1\n";
			print OUTtrashConsecutiveA "$line4PE1\n";
		}
		if (exists $hashINBLAST2{$readid2}){
			print OUTtrashAT "$line1PE2\n";
			print OUTtrashAT "$line2PE2\n";
			print OUTtrashAT "$line3PE2\n";
			print OUTtrashAT "$line4PE2\n";
			if ($hashINBLAST2{$readid2} eq $adapterLabel1){
				$countAdapter1PE2++;
			}elsif($hashINBLAST2{$readid2} eq $adapterLabel2){
				$countAdapter2PE2++;
			}
		}else{
			$countConsecutiveAreadsPE2++;
			print OUTtrashConsecutiveA "$line1PE2\n";
			print OUTtrashConsecutiveA "$line2PE2\n";
			print OUTtrashConsecutiveA "$line3PE2\n";
			print OUTtrashConsecutiveA "$line4PE2\n";
		}
	}elsif(($line2PE1 =~ /A{$thresholdOfConsecutiveA,}/) || (exists $hashINBLAST1{$readid1})){
		if (exists $hashINBLAST1{$readid1}){
			print OUTtrashAT "$line1PE1\n";
			print OUTtrashAT "$line2PE1\n";
			print OUTtrashAT "$line3PE1\n";
			print OUTtrashAT "$line4PE1\n";
			if ($hashINBLAST1{$readid1} eq $adapterLabel1){
				$countAdapter1PE1++;
			}elsif($hashINBLAST1{$readid1} eq $adapterLabel2){
				$countAdapter2PE1++;
			}
		}else{
			$countConsecutiveAreadsPE1++;
			print OUTtrashConsecutiveA "$line1PE1\n";
			print OUTtrashConsecutiveA "$line2PE1\n";
			print OUTtrashConsecutiveA "$line3PE1\n";
			print OUTtrashConsecutiveA "$line4PE1\n";
		}
		print OUTsingle "$line1PE2\n";
		print OUTsingle "$line2PE2\n";
		print OUTsingle "$line3PE2\n";
		print OUTsingle "$line4PE2\n";
	}elsif (($line2PE2 =~ /A{$thresholdOfConsecutiveA,}/) || (exists $hashINBLAST2{$readid2})){
		if (exists $hashINBLAST2{$readid2}){
			print OUTtrashAT "$line1PE2\n";
			print OUTtrashAT "$line2PE2\n";
			print OUTtrashAT "$line3PE2\n";
			print OUTtrashAT "$line4PE2\n";
			if ($hashINBLAST2{$readid2} eq $adapterLabel1){
				$countAdapter1PE2++;
			}elsif ($hashINBLAST2{$readid2} eq $adapterLabel2){
				$countAdapter2PE2++;
			}
		}else{
			$countConsecutiveAreadsPE2++;
			print OUTtrashConsecutiveA "$line1PE2\n";
			print OUTtrashConsecutiveA "$line2PE2\n";
			print OUTtrashConsecutiveA "$line3PE2\n";
			print OUTtrashConsecutiveA "$line4PE2\n";
		}
		print OUTsingle "$line1PE1\n";
		print OUTsingle "$line2PE1\n";
		print OUTsingle "$line3PE1\n";
		print OUTsingle "$line4PE1\n";
	}else{
		print OUTpreservedPE1 "$line1PE1\n";
		print OUTpreservedPE1 "$line2PE1\n";
		print OUTpreservedPE1 "$line3PE1\n";
		print OUTpreservedPE1 "$line4PE1\n";
		print OUTpreservedPE2 "$line1PE2\n";
		print OUTpreservedPE2 "$line2PE2\n";
		print OUTpreservedPE2 "$line3PE2\n";
		print OUTpreservedPE2 "$line4PE2\n";
	}
}
close OUTpreservedPE1;
close OUTpreservedPE2;
close OUTsingle;
close OUTtrashConsecutiveA;
close OUTtrashAT;
close INsolexaReads1;
close INsolexaReads2;
print "complete!\n";

###############################################################
# print statistical information to screen
my $statisticalReportFilename = $o.$prefix."_Statistical_Report.txt";
open (STDOUT, "| tee -ai $statisticalReportFilename");
print "-------------------------------------------\n";
print "Statistical Information:\n";
print "-------------------------------------------\n";
print "Parameters used in this run:\n";
print "-------------------------------------------\n";
print "Platform:\t\t\tSolexa\n";
print "Reads Type:\t\t\tPaired-end\n";
print "Adapter Sequence File Used:\t$adapterSeq\n";
print "Read Lenth:\t\t\t$readlength\n";
print "Threshold of As:\t\t$thresholdOfConsecutiveA\n";
print "-------------------------------------------\n";
print "PE NO1:\n";
print "#Total Reads: $countReads\n";
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel1, $countAdapter1PE1, $countAdapter1PE1/$countReads;
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel2, $countAdapter2PE1, $countAdapter2PE1/$countReads;
printf "#Reads with Consecutive A: %d (Ratio: %1.6f)\n", $countConsecutiveAreadsPE1, $countConsecutiveAreadsPE1/$countReads;
print "\nDistribution of the number of A in a read:\n";
print "#A\t#reads\n";
for (1..$readlength+1){
	my $index = $_-1;
	print "$index\t$distributionNumPE1[$index]\n";
}
print "\nDistribution of the position of A in a read:\n";
print "position\t#reads\n";
for (1..$readlength){
	print "$_\t\t$distributionPositionPE1[$_-1]\n";
}
print "\n-------------------------------------------\n";
print "PE NO2:\n";
print "#Total Reads: $countReads\n";
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel1, $countAdapter1PE2, $countAdapter1PE2/$countReads;
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel2, $countAdapter2PE2, $countAdapter2PE2/$countReads;
printf "#Reads with Consecutive A: %d (Ratio: %1.6f)\n", $countConsecutiveAreadsPE2, $countConsecutiveAreadsPE2/$countReads;
print "\nDistribution of the number of A in a read:\n";
print "#A\t#reads\n";
for (1..$readlength+1){
	my $index = $_-1;
	print "$index\t$distributionNumPE2[$index]\n";
}
print "\nDistribution of the position of A in a read:\n";
print "position\t#reads\n";
for (1..$readlength){
	print "$_\t\t$distributionPositionPE2[$_-1]\n";
}
print "\n-------------------------------------------\n";
close (STDOUT);
