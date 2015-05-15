#!/usr/bin/perl -w

use warnings;
use strict;
use Getopt::Std;
use Getopt::Long;

###############################################################
# input options
my $usage = qq(
Usage:      batchQC_N_AT.pl Parameters

Parameters: solexaReadsPE_NO1                 Counterpart 1 of Solexa PE reads sequence file in fastq format. (file)
            solexaReadsPE_NO2                 Counterpart 2 of Solexa PE reads sequence file in fastq format. (file)
            adapterSequence                   Adapter sequence file in fasta format. (file)
            filenamePrefix                    Prefix for the file name of output. (string)
            readLength                        Read lengh. (number)
            thresholdOfConsecutiveN           Threshold for the number of consecutive N in a read. Default: 5. (number)

Example:    batchQC_N_AT.pl -solexaReadsPE_NO1 s_1_1_sequence.txt -solexaReadsPE_NO2 s_1_2_sequence.txt -adapterSequence adapterSequence.txt -filenamePrefix s_1 -readLength 36 -thresholdofConsecutiveN 5
\n);

my $solexaReads1 = "";
my $solexaReads2 = "";
my $adapterSeq = "";
my $prefix = "";
my $readlength = "";
my $thresholdOfConsecutiveN = 5;

&GetOptions
(
 "solexaReadsPE_NO1:s" => \$solexaReads1,
 "solexaReadsPE_NO2:s" => \$solexaReads2,
 "adapterSequence:s" => \$adapterSeq,
 "filenamePrefix:s" => \$prefix,
 "readLength:s" => \$readlength,
 "thresholdOfConsecutiveN:s" => \$thresholdOfConsecutiveN,
);

die($usage) if ($solexaReads1 eq "" || $solexaReads2 eq "" || $adapterSeq eq "" || $prefix eq "" || $readlength eq "" || $thresholdOfConsecutiveN eq "");

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
# fastq2fasta
print "\n\n-------------------------------------------\n";
print "PROGRESS:\n";
print "fastq2fasta......";
open INsolexaReads1, "$solexaReads1" or die "$!";
open INsolexaReads2, "$solexaReads2" or die "$!";
my $outputNameSolexaReads1Fasta = $prefix."_fasta1";
my $outputNameSolexaReads2Fasta = $prefix."_fasta2";
open OUTsolexaReads1, ">>$outputNameSolexaReads1Fasta" or die "$!";
open OUTsolexaReads2, ">>$outputNameSolexaReads2Fasta" or die "$!";
while (<INsolexaReads1>) {
	if (/^@(\S+)/) {
		print OUTsolexaReads1 ">$1\n";
	  	$_ = <INsolexaReads1>; print OUTsolexaReads1;
	  	<INsolexaReads1>; <INsolexaReads1>;
	}
}
close INsolexaReads1;
close OUTsolexaReads1;
while (<INsolexaReads2>) {
	if (/^@(\S+)/) {
		print OUTsolexaReads2 ">$1\n";
	  	$_ = <INsolexaReads2>; print OUTsolexaReads2;
	  	<INsolexaReads2>; <INsolexaReads2>;
	}
}
close INsolexaReads2;
close OUTsolexaReads2;
print "complete!\n";

###############################################################
# blast
print "blast......";
open testExist1, "$outputNameSolexaReads1Fasta" or die "$!";
open testExist2, "$outputNameSolexaReads2Fasta" or die "$!";
close testExist1;
close testExist2;
my $bsubReturn;
$bsubReturn = `bsub -n 1 -q serial -o job.log -e job.err formatdb -i $outputNameSolexaReads1Fasta -p F -l $outputNameSolexaReads1Fasta.logfile -o `;
if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
	&bsubDog($1);
}else{
	die "bsub error!\n";
}
$bsubReturn = `bsub -n 1 -q serial -o job.log -e job.err formatdb -i $outputNameSolexaReads2Fasta -p F -l $outputNameSolexaReads2Fasta.logfile -o `;
if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
	&bsubDog($1);
}else{
	die "bsub error!\n";
}
my $outputNameBlast1 = $prefix."_nblast1";
my $outputNameBlast2 = $prefix."_nblast2";
$bsubReturn = `bsub -n 8 -q normal -o job.log -e job.err blastall -a 8 -p blastn -d $outputNameSolexaReads1Fasta -i $adapterSeq -G 2 -E 1 -F F -b 1000000 -m 9 -o $outputNameBlast1`;
if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
	&bsubDog($1);
}else{
	die "bsub error!\n";
}
$bsubReturn = `bsub -n 8 -q normal -o job.log -e job.err blastall -a 8 -p blastn -d $outputNameSolexaReads2Fasta -i $adapterSeq -G 2 -E 1 -F F -b 1000000 -m 9 -o $outputNameBlast2`;
if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
	&bsubDog($1);
}else{
	die "bsub error!\n";
}
print "complete!\n";

###############################################################
# getBlastResult
open INBLAST1, "$outputNameBlast1" or die "$!";
my %hashINBLAST1;
while(<INBLAST1>){
	chomp;
	if(!/^#/){
		my @parts = split /\t/;
		$hashINBLAST1{$parts[1]} = $parts[0];
	}
}
close INBLAST1;

open INBLAST2, "$outputNameBlast2" or die "$!";
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
my $outputNameTrashN = $prefix."_trashConsecutiveN";
my $outputNameTrashAdapter = $prefix."_trashAdapter";
open OUTpreservedPE1, ">>$outputNamePreservedPE1" or die "$!";
open OUTpreservedPE2, ">>$outputNamePreservedPE2" or die "$!";
open OUTsingle, ">>$outputNameSingle" or die "$!";
open OUTtrashConsecutiveN, ">>$outputNameTrashN" or die "$!";
open OUTtrashAT, ">>$outputNameTrashAdapter" or die "$!";
open INsolexaReads1, "$solexaReads1" or die "$!";
open INsolexaReads2, "$solexaReads2" or die "$!";

my $inputLinePE1;
my $inputLinePE2;
my $line1PE1;
my $line2PE1;
my $line3PE1;
my $line4PE1;
my $line1PE2;
my $line2PE2;
my $line3PE2;
my $line4PE2;
my $countReads4lines  = 1;
my $offsetPE1 = 0;
my $offsetPE2 = 0;
my @distributionNumPE1;
my @distributionNumPE2;
my @distributionPositionPE1;
my @distributionPositionPE2;
my $countAdapter1PE1 = 0;
my $countAdapter2PE1 = 0;
my $countAdapter1PE2 = 0;
my $countAdapter2PE2 = 0;
my $countReads = 0;
my $countConsecutiveNreadsPE1 = 0;
my $countConsecutiveNreadsPE2 = 0;
my $polyN_PE1;
my $polyN_PE2;
my $locPE1;
my $locPE2;

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
	$polyN_PE1 = ( $line2PE1 =~ tr/N// );
	$polyN_PE2 = ( $line2PE2 =~ tr/N// );
	$distributionNumPE1[$polyN_PE1]++;
	$distributionNumPE2[$polyN_PE2]++;
	$locPE1 = index $line2PE1, 'N', $offsetPE1;
	while ($locPE1 != -1){
		$distributionPositionPE1[$locPE1]++;
		$offsetPE1 = $locPE1 + 1;
		$locPE1 = index $line2PE1, 'N', $offsetPE1;
	}
	$locPE2 = index $line2PE2, 'N', $offsetPE2;
	while ($locPE2 != -1){
		$distributionPositionPE2[$locPE2]++;
		$offsetPE2 = $locPE2 + 1;
		$locPE2 = index $line2PE2, 'N', $offsetPE2;
	}
	$offsetPE1 = 0;
	$offsetPE2 = 0;
	my ($readid1) = ($line1PE1 =~ /^@(\S+)/);
	my ($readid2) = ($line1PE2 =~ /^@(\S+)/);
	if ((($line2PE1 =~ /N{$thresholdOfConsecutiveN,}/) || (exists $hashINBLAST1{$readid1})) && (($line2PE2 =~/N{$thresholdOfConsecutiveN,}/) || (exists $hashINBLAST2{$readid2}))){
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
			$countConsecutiveNreadsPE1++;
			print OUTtrashConsecutiveN "$line1PE1\n";
			print OUTtrashConsecutiveN "$line2PE1\n";
			print OUTtrashConsecutiveN "$line3PE1\n";
			print OUTtrashConsecutiveN "$line4PE1\n";
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
			$countConsecutiveNreadsPE2++;
			print OUTtrashConsecutiveN "$line1PE2\n";
			print OUTtrashConsecutiveN "$line2PE2\n";
			print OUTtrashConsecutiveN "$line3PE2\n";
			print OUTtrashConsecutiveN "$line4PE2\n";
		}
	}elsif(($line2PE1 =~ /N{$thresholdOfConsecutiveN,}/) || (exists $hashINBLAST1{$readid1})){
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
			$countConsecutiveNreadsPE1++;
			print OUTtrashConsecutiveN "$line1PE1\n";
			print OUTtrashConsecutiveN "$line2PE1\n";
			print OUTtrashConsecutiveN "$line3PE1\n";
			print OUTtrashConsecutiveN "$line4PE1\n";
		}
		print OUTsingle "$line1PE2\n";
		print OUTsingle "$line2PE2\n";
		print OUTsingle "$line3PE2\n";
		print OUTsingle "$line4PE2\n";
	}elsif (($line2PE2 =~ /N{$thresholdOfConsecutiveN,}/) || (exists $hashINBLAST2{$readid2})){
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
			$countConsecutiveNreadsPE2++;
			print OUTtrashConsecutiveN "$line1PE2\n";
			print OUTtrashConsecutiveN "$line2PE2\n";
			print OUTtrashConsecutiveN "$line3PE2\n";
			print OUTtrashConsecutiveN "$line4PE2\n";
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
close OUTtrashConsecutiveN;
close OUTtrashAT;
close INsolexaReads1;
close INsolexaReads2;
print "complete!\n";

###############################################################
# remove temporary files
print "remove temporary files......";
my $rmNameFastaBlastPE1 = $outputNameSolexaReads1Fasta."*";
my $rmNameFastaBlastPE2 = $outputNameSolexaReads2Fasta."*";
system ("rm $rmNameFastaBlastPE1 $rmNameFastaBlastPE2 $outputNameBlast1 $outputNameBlast2");
print "complete!\n";

###############################################################
# watch dog for bsub
sub bsubDog {
	if (!defined(@_)){
		die "bsubErr!\n";
	}
	my $watchdog;
	my @tmp;
	while (1) {
		@tmp = `bjobs`;
		foreach (@tmp) {
			chomp;
			if (/^(@_)/) {
				$watchdog = $1;
			}
		}
		if ( defined($watchdog) ) {
			undef $watchdog;
			sleep 5;
			next;
		}
		else {
			return 1;
			last;
		}
	}
}

###############################################################
# print statistical information to screen
my $statisticalReportFilename = $prefix."_Statistical_Report.txt";
open (STDOUT, "| tee -ai $statisticalReportFilename");
print "-------------------------------------------\n";
print "Statistical Information:\n";
print "-------------------------------------------\n";
print "PE NO1:\n";
print "#Total Reads: $countReads\n";
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel1, $countAdapter1PE1, $countAdapter1PE1/$countReads;
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel2, $countAdapter2PE1, $countAdapter2PE1/$countReads;
printf "#Reads with Consecutive N: %d (Ratio: %1.6f)\n", $countConsecutiveNreadsPE1, $countConsecutiveNreadsPE1/$countReads;
print "\nDistribution of the number of N in a read:\n";
print "#N\t#reads\n";
for (1..$readlength+1){
	my $index = $_-1;
	print "$index\t$distributionNumPE1[$index]\n";
}
print "\nDistribution of the position of N in a read:\n";
print "position\t#reads\n";
for (1..$readlength){
	print "$_\t\t$distributionPositionPE1[$_-1]\n";
}
print "\n-------------------------------------------\n";
print "PE NO2:\n";
print "#Total Reads: $countReads\n";
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel1, $countAdapter1PE2, $countAdapter1PE2/$countReads;
printf "#Reads with %s: %d (Ratio: %1.6f)\n", $adapterLabel2, $countAdapter2PE2, $countAdapter2PE2/$countReads;
printf "#Reads with Consecutive N: %d (Ratio: %1.6f)\n", $countConsecutiveNreadsPE2, $countConsecutiveNreadsPE2/$countReads;
print "\nDistribution of the number of N in a read:\n";
print "#N\t#reads\n";
for (1..$readlength+1){
	my $index = $_-1;
	print "$index\t$distributionNumPE2[$index]\n";
}
print "\nDistribution of the position of N in a read:\n";
print "position\t#reads\n";
for (1..$readlength){
	print "$_\t\t$distributionPositionPE2[$_-1]\n";
}
print "\n-------------------------------------------\n";
close (STDOUT);

