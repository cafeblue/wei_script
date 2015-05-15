#! /usr/bin/perl -w

# this script will convert the two fastq file into one paired 
# end 454 reads file .fna and the corresponding qulity file .qual 

use strict;
use Bio::SeqIO;
use Bio::Seq::Quality;

if (@ARGV < 3) {
    print "\n\tUsage: $0 input1.fastq input2.fastq outfile\n";
    exit(0);
}

my $lines = `wc -l $ARGV[0]`;
$lines = (split(/\s/, $lines))[0];
$lines /= 4;
my $fna_file = $ARGV[2]."\.fna";
my $qual_file = $ARGV[2]."\.qual";
my $input1 = $ARGV[0];
my $input2 = $ARGV[1];

my $seq_out  = Bio::SeqIO->new( -format => 'fasta', -file => ">$fna_file");
my $qual_out = Bio::SeqIO->new(-file => ">$qual_file", -format => 'fastq');

my $in1 = Bio::SeqIO->new( -file => "$input1", -format => 'fastq');
my $in2 = Bio::SeqIO->new( -file => "$input2", -format => 'fastq');

for (my $i=0; $i < $lines; $i++) {
	my $seq_obj1;
	my $seq_obj2;
	my $out_seq;
	my $out_qual;
    $seq_obj1 = $in1->next_seq();
	$seq_obj2 = $in2->next_seq();
	$out_seq = $seq_obj2->seq();
	$out_seq =~ tr/ATGCatgc/TACGtacg/;
	$out_seq = reverse($out_seq) . "GTTGGAACCGAAAGGGTTTGAATTCAAACCCTTTCGGTTCCAAC";
	my $tmp = join(' ',reverse(split(' ',$seq_obj2->qual_text())));
	$out_qual .= $tmp . " 40" x 44 . " ";
	$out_seq .= $seq_obj1->seq();
	$out_qual .= $seq_obj1->qual_text();
#	print $out_qual;
    my $qual_obj_write = Bio::Seq::Quality->new( -qual => $out_qual, -seq => $out_seq, -id => $seq_obj1->display_id(), -verbose => -1 );
#	$qual_obj_write->qual
    $seq_out->write_seq($qual_obj_write);
    $qual_out->write_qual($qual_obj_write);
}
