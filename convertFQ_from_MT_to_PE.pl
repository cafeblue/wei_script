#! /usr/bin/perl -w

# convert the Mate Paired sequences to Paired End sequences.
# for the direction of Mate Paired sequences is Forward-forward.
# while the Paired End sequences is Forward-backward.

# so my job is convert the read1 to sequences to reversed complementary 
# sequences.

# Writen by Wang Wei Sep. 26 2009

use strict;
#use Bio:SeqIO;
#use Bio::Seq::Quality;

if (@ARGV < 2) {
	print "\n\tUsage: $0 in_file out_file";
	print "\n\tExample: $0 s_3_1_sequence.txt out.fastq\n";
	exit(0);
}

open (INF, "$ARGV[0]") || die $!;
open (OUT, ">$ARGV[1]") || die $!;
#my $in = Bio::SeqIO->new( -file => "$ARGV[0]", -format => 'fastq');
#my $out = Bio::SeqIO->new( -file => ">$ARGV[1]", -format => 'fastq');
my $line = 1;

while (<INF>) {
	chomp;
	if ($line%4 == 0) {
		$_ = scalar reverse($_);
	}
	elsif ($line%4 == 2) {
		tr/ATGC/TACG/;
		$_ = scalar reverse($_);
#		print OUT $_,"\n";
#		$line++;
#		next;
	}
	print OUT $_,"\n";
	$line++;
#	next;
}		
