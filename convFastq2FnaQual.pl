#! /bin/env perl

# used to convert the .fastq file to a .fna and .qual file

use strict;
use Bio::SeqIO;
use Bio::Seq::Quality;

if (@ARGV < 3) {
	print "\n\tUsage: $0 input.fastq outfile.fna outfile.qual\n";
	exit(0);
}

my $fna_file = $ARGV[1];
my $qual_file = $ARGV[2];
my $input = $ARGV[0];

my $seq_out  = Bio::SeqIO->new( -format => 'fasta', -file => ">$fna_file");
my $qual_out = Bio::SeqIO->new(-file => ">$qual_file", -format => 'fastq');
my $in = Bio::SeqIO->new( -file => "$input", -format => 'fastq');

while ( my $seq_obj = $in->next_seq() ) {
#	my $qual_obj = $seqqual->next_seq();
	my $qual_obj_write = Bio::Seq::Quality->new( -qual => $seq_obj->qual(), -seq => $seq_obj->seq(), -id => $seq_obj->display_id(), -verbose => -1 );
    $seq_out->write_seq($qual_obj_write);
	$qual_out->write_qual($qual_obj_write);
}



