#!/usr/bin/perl -w

use warnings;
use strict;
use Getopt::Std;
use Getopt::Long;

###############################################################
# input options
my $usage = qq(
Usage:      batchFilter_A_AT_solexaNonPE.pl Parameters

Parameters: solexaReads                       Solexa non-PE reads sequence file in fastq format. (file)
            adapterSequence                   Adapter sequence file in fasta format. (file)
            blastresult                       result of blasting adapter1 and 2 against solexa resds using ncbi blastn in m9 format. (file)
            filenamePrefix                    Prefix for the file name of output. (string)
            thresholdOfConsecutiveA           Threshold for the number of consecutive A in a read. Default: 15. (number)
            o                                 directory of output.(directory of file system)

Example:    batchFilter_A_AT_solexaNonPE.pl -solexaReads s_1_sequence.txt -adapterSequence adapterSequence.txt -filenamePrefix s_1 -readLength 36 -thresholdofConsecutiveA 15 -o /home/gene/escience/tmp/
\n);

my $solexaReads = "";
my $adapterSeq = "";
my $blastresult = "";
my $prefix = "";
my $thresholdOfConsecutiveA = 15;
my $o = "";

&GetOptions
(
 "solexaReads:s" => \$solexaReads,
 "adapterSequence:s" => \$adapterSeq,
 "blastresult:s" => \$blastresult,
 "filenamePrefix:s" => \$prefix,
 "thresholdOfConsecutiveA:s" => \$thresholdOfConsecutiveA,
 "o:s" => \$o,
);

die($usage) if ($solexaReads eq "" || $adapterSeq eq "" || $blastresult eq "" || $prefix eq "" || $thresholdOfConsecutiveA eq "" || $o eq "");

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
open INBLAST, "$blastresult" or die "$!";
my %hashINBLAST;
while(<INBLAST>){
	chomp;
	if(!/^#/){
		my @parts = split /\t/;
		$hashINBLAST{$parts[1]} = $parts[0];
	}
}
close INBLAST;

###############################################################
# loop through each read
print "loop through each read......";
my $outputNameSingle = $prefix."_single";
my $outputNameTrashA = $prefix."_trashConsecutiveA";
my $outputNameTrashAdapter = $prefix."_trashAdapter";
my $outputPathNameSingle = $o.$outputNameSingle;
my $outputPathNameTrashA = $o.$outputNameTrashA;
my $outputPathNameTrashAdapter = $o.$outputNameTrashAdapter;
open OUTsingle, ">>$outputPathNameSingle" or die "$!";
open OUTtrashConsecutiveA, ">>$outputPathNameTrashA" or die "$!";
open OUTtrashAT, ">>$outputPathNameTrashAdapter" or die "$!";
open INsolexaReads, "$solexaReads" or die "$!";

my ($inputLine, $line1, $line2, $line3, $line4);
my $countReads4lines  = 1;
my $offset = 0;
my (@distributionNum, @distributionPosition);
my $countAdapter1 = 0;
my $countAdapter2 = 0;
my $countReads = 0;
my $countConsecutiveAreads = 0;
my ($polyA, $loc);
my $readlength = `tail -1 $solexaReads | awk '{ print length }'`;
chomp $readlength;

for ( my $i = 0 ; $i < $readlength ; $i++ ) {
	$distributionNum[$i]      = 0;
	$distributionPosition[$i] = 0;
}
push @distributionNum,0;
while (defined($inputLine = <INsolexaReads>)) {
	chomp $inputLine;
	if ( $countReads4lines == 1 ) {
		$line1 = $inputLine;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 2 ) {
		$line2 = $inputLine;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 3 ) {
		$line3 = $inputLine;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	if ( $countReads4lines == 4 ) {
		$line4 = $inputLine;
		$countReads4lines++;
		if ( $countReads4lines < 5 ) {
			next;
		}
	}
	$countReads4lines = 1;
	$countReads++;
	$polyA = ( $line2 =~ tr/A// );
	$distributionNum[$polyA]++;
	$loc = index $line2, 'A', $offset;
	while ($loc != -1){
		$distributionPosition[$loc]++;
		$offset = $loc + 1;
		$loc = index $line2, 'A', $offset;
	}
	$offset = 0;
	my ($readid) = ($line1 =~ /^@(\S+)/);
	if (($line2 =~ /A{$thresholdOfConsecutiveA,}/) || (exists $hashINBLAST{$readid})){
		if (exists $hashINBLAST{$readid}){
			print OUTtrashAT "$line1\n";
			print OUTtrashAT "$line2\n";
			print OUTtrashAT "$line3\n";
			print OUTtrashAT "$line4\n";
			if ($hashINBLAST{$readid} eq $adapterLabel1){
				$countAdapter1++;
			}elsif($hashINBLAST{$readid} eq $adapterLabel2){
				$countAdapter2++;
			}
		}else{
			$countConsecutiveAreads++;
			print OUTtrashConsecutiveA "$line1\n";
			print OUTtrashConsecutiveA "$line2\n";
			print OUTtrashConsecutiveA "$line3\n";
			print OUTtrashConsecutiveA "$line4\n";
		}
	}else{
		print OUTsingle "$line1\n";
		print OUTsingle "$line2\n";
		print OUTsingle "$line3\n";
		print OUTsingle "$line4\n";
	}
}
close OUTsingle;
close OUTtrashConsecutiveA;
close OUTtrashAT;
close INsolexaReads;

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
print "Reads Type:\t\t\tnon-Paired-end\n";
print "Adapter Sequence File Used:\t$adapterSeq\n";
print "Read Lenth:\t\t\t$readlength\n";
print "Threshold of As:\t\t$thresholdOfConsecutiveA\n";
print "-------------------------------------------\n";
print "#Total Reads: $countReads\n";
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel1, $countAdapter1, $countAdapter1/$countReads;
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel2, $countAdapter2, $countAdapter2/$countReads;
printf "#Reads with Consecutive A: %d (Ratio: %1.6f)\n", $countConsecutiveAreads, $countConsecutiveAreads/$countReads;
print "\nDistribution of the number of A in a read:\n";
print "#A\t#reads\n";
for (1..$readlength+1){
	my $index = $_-1;
	print "$index\t$distributionNum[$index]\n";
}
print "\nDistribution of the position of A in a read:\n";
print "position\t#reads\n";
for (1..$readlength){
	print "$_\t\t$distributionPosition[$_-1]\n";
}
print "\n-------------------------------------------\n";
close (STDOUT);
