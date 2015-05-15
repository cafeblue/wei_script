#! /bin/env perl

use strict;
use Bio::SeqIO;

my $usage = <<USAGE;

    Usage: $0 infile outfile
    Example: $0 inframe_nt.fa inframe_aa.fa

USAGE

if ($#ARGV < 1) {
    die $usage;
}

my $seqi = Bio::SeqIO->new( -file => "$ARGV[0]", -format => "fasta");
my $seqo = Bio::SeqIO->new( -file => ">$ARGV[1]", -format => "fasta");

while (my $seqobj = $seqi->next_seq) {
    my ($start ,$end) = (split(/__/, $seqobj->id()))[2,3];
    my $seqout = $seqobj->trunc($start, $end)->translate;
    $seqo->write_seq($seqout);
}
