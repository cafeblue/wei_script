#! /usr/bin/perl -w

# input file should be a fasta file contains only one sequence.
# R/F means output the reverse sequences or not
use strict;
use Bio::SeqIO;

if (@ARGV < 3) {
	print "\n\tUsage: $0 input_file range, R/F output_file";
	print "\n\tExample: $0 in.fasta 1000,1200 R out.fasta\n";
	exit(0);
}

my $seqfile_obj_in = Bio::SeqIO->new(-file=>"$ARGV[0]");
my $seqfile_obj_out = Bio::SeqIO->new(-file=>">$ARGV[3]", -format=>"fasta");

my $seqin = $seqfile_obj_in->next_seq;
my ($start, $end) = split(/,/, $ARGV[1]);
my $seqstring = $seqin->subseq($start, $end);
my $id = $seqin->display_id();
my $seq_obj_o = Bio::Seq->new(-display_id=>"$id", -seq=>"$seqstring");

if ($ARGV[2] eq "R" || $ARGV[2] eq "r") {
	$seq_obj_o = $seq_obj_o->revcom;
}

$seqfile_obj_out->write_seq($seq_obj_o);

