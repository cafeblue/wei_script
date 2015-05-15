#! /usr/bin/perl -w

# this script used to choose the length Range sequences from
# a fasta file.

# the first parameter is the fasta file.
# the second parameters is the cutoff of the length.
# the third parameter is the new fasta file.

use strict;

if (@ARGV < 3) {
	die "\tUsage: $0 inputfile range outputfile\n\tExample: $0 Sja.aa m100 output.fasta\t (chose sequences longer than 100)\n\t\t $0 Sja.aa l100 output.fasta\t (choose sequences shorter than 100)\n\t\t $0 Sja.aa 100,120,140,180-200 output.fasta\t (choose the sequences equal 100, 120, 140 and between 180 and 200)\n";
}

open (A, "<$ARGV[0]") || die $!;
my %hash1;
my $id;

while (<A>) {
	chomp;
	if (/^>/) {
		$id = $_;
	}
	else {
		$hash1{$id} .= $_;
	}
}

open (B, ">$ARGV[2]");

sub single {
	foreach (keys %hash1) {
		if (length($hash1{$_}) == $_[0]) {
			print B $_,"\n";
			print B $hash1{$_},"\n";
		}
	}
}

sub double {
	my @two = split('-', $_[0]);
	foreach (keys %hash1) {
		if (length($hash1{$_}) >= $two[0] && length($hash1{$_}) <= $two[1]) {
			print B $_,"\n";
			print B $hash1{$_},"\n";
		}
	}
}

my $para1 = $ARGV[1];

if ($para1 =~ /^m/) {
	$para1 =~ s/m//;
	foreach (keys %hash1) {
		if (length($hash1{$_}) >= $para1) {
			print B $_,"\n";
			print B $hash1{$_},"\n";
		}
	}
}

elsif ($para1 =~ /^l/) {
	$para1 =~ s/l//;
	foreach (keys %hash1) {
		if (length($hash1{$_}) <= $para1) {
			print B $_,"\n";
			print B $hash1{$_},"\n";
		}
	}
}

elsif ($para1 =~ /^[0-9]+$/) {
	single($para1);
}

elsif ($para1 =~ /^[0-9]+-[0-9]+$/) {
	double($para1);
}

elsif ($para1 =~ /\,/) {
	my @multi = split(',', $para1);
	foreach (@multi) {
		if (/^[0-9]+$/) {
			single($_);
		}
		elsif (/^[0-9]+-[0-9]+$/) {
			double($_);
		}
	}
}
