#! /usr/bin/perl -w

# used to extract the reads contains poly Ns.

# writen by Wei Wang Jun 7 2010.

use strict;
use Bio::SeqIO;
use Bio::Seq;

if (@ARGV < 3) {
	print "\n\tUsage: $0 inputfile Base(A/T or G/C) Length outfile";
	print "\n\tExample: $0 454AllReads.fna G/C 6 out.fasta\n";
	exit(0);
}

my $patent = (split(/\//, $ARGV[1]))[0];
$patent = "$patent" x $ARGV[2];
my $patent1 = (split(/\//, $ARGV[1]))[1];
$patent1 = "$patent1" x $ARGV[2];

my $seqin = Bio::SeqIO->new(-format=>"fasta", -file=>"$ARGV[0]");
my $seqout = Bio::SeqIO->new(-format=>"fasta", -file=>">$ARGV[3]");

while (my $seqobj = $seqin->next_seq()) {
	if ($seqobj->seq() =~ /$patent/i || $seqobj->seq() =~ /$patent1/i) {
		my $seqout_obj = Bio::Seq->new(-id=>$seqobj->display_id(), -seq=>$seqobj->seq());
		$seqout->write_seq($seqout_obj);
	}
}
	
