#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
use vars qw($opt_c $opt_l $opt_t $opt_i $opt_v);
getopts('c:l:t:i:v:');
my $cpu            =$opt_c ? $opt_c : 4;
my $length         =$opt_l ? $opt_l : 15;
my $type           =$opt_t ? $opt_t : "common";
my $list           =$opt_i;
my $version        =$opt_v ? $opt_v : "version 0.1";

my $program_name=$1 if($0=~/([^\/]+)$/);
my $usage=<<USAGE; #******* Instruction of this program *********# 

Program: multiple processes running cutadapt 
version 0.1

Usage: perl $program_name -cpu <int> -l <int> -type <adapter type> <FILE LIST>
-c    <int>          number of CPU to use, default=4
-l    <int>          Minimum overlap length, default=4
-t    <adapter type> common: common adapter
                     sRNA  : sRNA   adapter
-i                   input file list

FILE LIST FILE FORM
fq:<file_name>
fq:<file_name>
...

USAGE

die $usage unless ( $list );

my %hash;
$hash{common}="-a AGATCGGAAGAGCACACGTC -a AGATCGGAAGAGCGTCGTGT";
$hash{sRNA}  ="-a GTTCAGAGTTCTACAGTCCG -a CTGTAGGCACCATCAATCGT";

my $not_exists="this adapter type is not exists!\n";
die $not_exists if (!exists $hash{$type});

my @fq;
my $i=0;

open IN,$list;
while (<IN>) {
	chomp;
	if (/fq:(\S+).fastq.gz/) {
		$fq[$i]=$1;
		$i++;
	}
}
close IN;

my $name;

open SCRIPT,">$list.cmd";

foreach $name (@fq) {
	print SCRIPT "/share/data/staff/wangw/cutadapt/cutadapt $hash{$type} ";
	print SCRIPT "-O $length -o $name\_cut.fasq.gz --untrimmed-output=$name\_nocut.fastq.gz $name.fastq.gz 2>$name.log\n";
	
}
close SCRIPT;

system "perl /share/data3/staff/tianf/bin/multi-process.pl -cpu $cpu $list.cmd";

open LOG,">$list.xls";
print LOG "Sample ID\tProcessed reads\tTrimmed reads\tTrimmed ratio\n";
foreach $name (@fq) {
	open RLOG,"$name.log";
	print LOG "$name\t";
	while (<RLOG>) {
		chomp;
		if (/Processed reads:\s+(\d+)/) {
			print LOG "$1\t";
		}
		elsif (/Trimmed reads:\s+(\d+)\s+\(\s+(\d+\.\d+\%)\)/) {
			print LOG "$1\t$2\t";
		}
	}
	print "\n";
}
close LOG;
