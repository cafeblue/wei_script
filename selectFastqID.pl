#! /usr/bin/perl -w

# this script will extract the IDs in a list file from a fastq file.
# Writen by Wang Wei Sep. 7, 2009 

use strict;
use Bio::SeqIO;
use Bio::Seq::Quality;


if (@ARGV < 3) {
    print "\n\tUsage: $0 reads_list fastq_file outfile";
    print "\n\tExample: $0 list.txt s_7_1_sequences.txt now_reads.fq\n";
    exit(0);
}

my $counter = 0;
my %list;

# read the id list into a hash.
open (INF, "$ARGV[0]") || die $!;
while (<INF>) {
    chomp;
	$counter++;
	s/^\@//;
    $list{$_} = "";
}
close(INF);

my $outfile1 = Bio::SeqIO->new(-format => 'fastq', -file => ">$ARGV[2]");
my $in1 = Bio::SeqIO->new( -file => "$ARGV[1]", -format => 'fastq');

while(my $seq_obj1 = $in1->next_seq()) {
	if (exists $list{$seq_obj1->display_id()}){
		$outfile1->write_fastq($seq_obj1);
		delete($list{$seq_obj1->display_id()});
		$counter--;
	}
	if ($counter == 0) {
		last;
	}
}

if ($counter > 0) { 
	foreach (keys %list) {
		print $_,"\tnot found!\n";
	}
}
