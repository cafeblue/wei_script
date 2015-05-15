#! /usr/bin/perl -w

use strict;
use Getopt::Std;

my %options=();
getopts("i:t:o:",\%options);

if ((scalar keys %options) < 2) {
	print "\tTrim fastq files into a short length\n";
	print "\tUsage: $0 -i infastqfile -t number -o outfastqfile\n";
	print "\tExample: $0 -i all.fastq -t 39 -o all_39.fastq\n";
	exit (0);
}

open (INF, "$options{i}") || die $!;
open (OUT, ">$options{o}") || die $!;

my $flag = 0;
while (<INF>) {
	if ($flag == 0) {
		print OUT $_;
		$flag++;
		next;
	}
	elsif ($flag == 1) {
		print OUT substr($_,0,$options{t}),"\n";
		$flag = 0;
		next;
	}
}
