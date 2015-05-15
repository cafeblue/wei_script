#!/usr/bin/perl
use strict;
use warnings;

my $program_name=$1 if($0=~/([^\/]+)$/);
my $usage=<<USAGE; #******* Instruction of this program *********# 

Program: multiple processes running cutadapt

Usage: perl $program_name  <command_file>

FILE FORM
cpu:<int>
length:<int> Minimum overlap length.
a:<adapter1>
a:<adapter2>
...
fq1:<file_name>	fq2:<file_name>
fq1:<file_name>	fq2:<file_name>
...

USAGE



if (@ARGV==0) {
	print "$usage";
}else {

my $cpu;
my $length;
my @adapter;
my @fq;
my $i=0;
my $j=0;
my $k=0;
my @count;
open IN,$ARGV[0];
while (<IN>) {
	chomp;
	if (/cpu:/) {
		$cpu=$';
		print "cpu:$cpu\n";
	}
	elsif (/length:/) {
		$length=$';
		print "length:$length\n";
	}
	elsif (/a:/) {
		$adapter[$i]=$';
		print "a:$adapter[$i]\n";
		$i++;
	}
	elsif (/fq1:(\S+).fastq.gz\s+fq2:(\S+).fastq.gz/) {
		$fq[$j][$k]=$1;
		$k++;
		$fq[$j][$k]=$2;
		print "fq1:$fq[$j][0]\tfq2:$fq[$j][1]\n";
		$count[$j]=$j;
		$j++;
		$k=0;
	}
}
close IN;

my $txt;
if ($ARGV[0]=~/\.txt/) {
	$txt=$`;
}
open SCRIPT,">$txt\_mt.txt";

foreach  (@count) {
	#print "$_\n";
	print SCRIPT "/share/data/staff/wangw/cutadapt/cutadapt ";
	my $ad;
	foreach $ad (@adapter) {
		chomp($ad);
		print SCRIPT "-a $ad ";
	}
	print SCRIPT "-O $length -o $fq[$_][0]\_cut.fasq.gz --untrimmed-output=$fq[$_][0]\_nocut.fastq.gz $fq[$_][0].fastq.gz 2>$fq[$_][0].log\n";
	print SCRIPT "/share/data/staff/wangw/cutadapt/cutadapt ";
	foreach $ad (@adapter) {
		chomp($ad);
		print SCRIPT "-a $ad ";
	}
	print SCRIPT "-O $length -o $fq[$_][1]\_cut.fasq.gz --untrimmed-output=$fq[$_][1]\_nocut.fastq.gz $fq[$_][1].fastq.gz 2>$fq[$_][1].log\n";
}
close SCRIPT;

system "perl /share/data3/staff/tianf/bin/multi-process.pl -cpu $cpu $txt\_mt.txt";

my $coun;
open LOG,">$txt\_mt.log";
foreach $coun (@count) {
	open RLOG,"$fq[$coun][0].log";
	print LOG "=======================================================================\n";
	print LOG "$fq[$coun][0]\n";
	print LOG "=======================================================================\n";
	while (<RLOG>) {
		chomp;
		if (/Processed reads:/) {
			print LOG "$_\n";
		}
		elsif (/Trimmed reads:/) {
			print LOG "$_\n";
		}
		elsif (/Total \time:/) {
			print LOG "$_\n";
		}
		elsif (/=== Adapter/) {
			print LOG "$_\n";
		}
		elsif (/Histogram of adapter lengths/) {
			print LOG "$_\n";
		}
		elsif (/\length/) {
			print LOG "$_\n";
		}
		elsif (/(\d+)\s+(\d+)/) {
			print LOG "$_\n";
		}
		
	}
	close RLOG;
	open RLOG,"$fq[$coun][1].log";
	print LOG "=======================================================================\n";
	print LOG "$fq[$coun][1]\n";
	print LOG "=======================================================================\n";
	while (<RLOG>) {
		chomp;
		if (/Processed reads:/) {
			print LOG "$_\n";
		}
		elsif (/Trimmed reads:/) {
			print LOG "$_\n";
		}
		elsif (/Total \time:/) {
			print LOG "$_\n";
		}
		elsif (/=== Adapter/) {
			print LOG "$_\n";
		}
		elsif (/Histogram of adapter lengths/) {
			print LOG "$_\n";
		}
		elsif (/\length/) {
			print LOG "$_\n";
		}
		elsif (/(\d+)\s+(\d+)/) {
			print LOG "$_\n";
		}
		
	}
	close RLOG;
}
close LOG;
}

