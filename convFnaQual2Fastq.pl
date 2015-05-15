#! /usr/bin/perl -w

# used to conver .fna and .qual file to a .fastq file

use strict;
use Bio::SeqIO;
use Bio::Seq::Quality;

if (@ARGV < 3) {
	print "\n\tUsage: $0 file.fna file.qual output.fastq\n";
	exit(0);
}

my $fna_file = $ARGV[0];
my $qual_file = $ARGV[1];
my $output = $ARGV[2];

my $seqio  = Bio::SeqIO->new( -format => 'fasta', -file => $fna_file);
my $seqqual = Bio::SeqIO->new(-file => $qual_file, -format => 'qual');
my $out = Bio::SeqIO->new( -file => ">$output", -format => 'fastq');

while ( my $seq_obj = $seqio->next_seq() ) {
	my $qual_obj = $seqqual->next_seq();
	my $qual_obj_write = Bio::Seq::Quality->new( -qual => $qual_obj->qual(), -seq => $seq_obj->seq(), -id => $seq_obj->display_id(), -verbose => -1 );
    $out->write_fastq($qual_obj_write);
}



