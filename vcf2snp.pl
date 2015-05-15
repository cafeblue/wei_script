#!/usr/bin/perl
if (@ARGV<4 || @ARGV>4) {
	die"perl vcf2snp.pl <VCF file> <SNP> <INDEL> <deepth_statistics>\n";
}
unless (-e $ARGV[0]){
	die"VCF file entered is not existent!\n";
}

use strict;
use warnings;

my @line;
my @line7;
my @dp4;
my $ref_dep=0;
my $nonref_dep=0;
my $chrome;
my @snp_count;
   $snp_count[0]=0;
   $snp_count[1]=0;
   $snp_count[2]=0;
my @indel_count;
   $indel_count[0]=0;
   $indel_count[1]=0;
   $indel_count[2]=0;
my $dep_indel;
my $dep_snp;
#my $count_test_snp=0;
#my $count_test_indel=0;


open (VCF,"<$ARGV[0]");
open (SNP,">$ARGV[1]");
open (INDEL,">$ARGV[2]");
open (DEP,">$ARGV[3]");
print DEP "Minimal_deepth\tSNP\tINDEL\n";
print SNP "ReferenceName\tPosition\tRefBase\tNon-ref_Base\tDepth_of_RefBase\tDepth_of_Non-ref_Base\tVarQuality\n";
print INDEL "ReferenceName\tPosition\tRefBase\tNon-ref_Base\tDepth_of_RefBase\tDepth_of_Non-ref_Base\tVarQuality\n";
while (<VCF>) {
	if ($_=~ /\#+/) {
		print $_;
		next;
	}
	@line=split(/\t/,$_);
	@line7=split(/\;/,$line[7]);
	if ($line7[0]=~ /INDEL/) {
		$line7[4]=~ /DP4\=(\w+,\w+,\w+,\w+)/;
		@dp4=split(/\,/,$1);
		$dp4[0]=$dp4[0] + 0;
		$dp4[1]=$dp4[1] + 0;
		$dp4[2]=$dp4[2] + 0;
		$dp4[3]=$dp4[3] + 0;
		$ref_dep=$dp4[0] + $dp4[1];
		$nonref_dep=$dp4[2] + $dp4[3];
		$dep_indel=$dp4[0] + $dp4[1] + $dp4[2] + $dp4[3];
		if ($dep_indel >= 20 ) {
			$indel_count[2]++;
		}
		elsif ($dep_indel >= 10 ) {
			$indel_count[1]++;
		}
		elsif ($dep_indel > 4 ) {
			$indel_count[0]++;
		}
#		elsif ($dep_indel <= 4 ) {
#			$count_test_indel++;
#		}

		print INDEL "$line[0]\t$line[1]\t$line[3]\t$line[4]\t$ref_dep\t$nonref_dep\t$line[5]\n";

	}
	else {
		$line7[3]=~ /DP4\=(\w+,\w+,\w+,\w+)/;
		@dp4=split(/\,/,$1);
		$dp4[0]=$dp4[0] + 0;
		$dp4[1]=$dp4[1] + 0;
		$dp4[2]=$dp4[2] + 0;
		$dp4[3]=$dp4[3] + 0;
		$ref_dep=$dp4[0] + $dp4[1];
		$nonref_dep=$dp4[2] + $dp4[3];
		$dep_snp=$dp4[0] + $dp4[1] + $dp4[2] + $dp4[3];
		if ($dep_snp >= 20 ) {
			$snp_count[2]++;
		}
		elsif ($dep_snp >= 10 ) {
			$snp_count[1]++;
		}
		elsif ($dep_snp > 4 ) {
			$snp_count[0]++;
		}

#		elsif ($dep_snp <= 4 ) {
#			$count_test_snp++;
#		}

		print SNP "$line[0]\t$line[1]\t$line[3]\t$line[4]\t$ref_dep\t$nonref_dep\t$line[5]\n";
	}
	
}
$snp_count[3]=$snp_count[0] + $snp_count[1] + $snp_count[2];
$snp_count[4]=$snp_count[1] + $snp_count[2];
$indel_count[3]=$indel_count[0] + $indel_count[1] + $indel_count[2];
$indel_count[4]=$indel_count[1] + $indel_count[2];

#print "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\nREST\t$count_test_snp\t$count_test_indel\n";
#print DEP "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\nREST\t$count_test_snp\t$count_test_indel\n";
print "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\n";
print DEP "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\n";

close DEP;
close VCF;
close SNP;
close INDEL;
