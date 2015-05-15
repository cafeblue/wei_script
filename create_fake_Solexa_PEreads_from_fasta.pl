#!/bin/env perl

# writen by Wang Wei sep. 11 2009
#
# this script used to chop the long seqs into 
# high coverage short pseudo reads.

use strict;
use Getopt::Long;
use Bio::Seq;
use Bio::SeqIO;

sub random{
	my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
	return join("", @chars[ map { rand @chars } ( 1 .. 5 ) ]);
}

my $seq_id = random();
my $seq_nu = "000000000";
my $fasta="";
my $qual_value=38;
my $output1="";
my $output2="";
my $insert_length = 180;
my $length_PE = 100;
my $expect_cov = 10;  # expected coverage

&GetOptions
(
 "fasta:s" => \$fasta,
 "outfile1:s" => \$output1,
 "outfile2:s" => \$output2,
 "qual:s" => \$qual_value,
 "insertlength:s" => \$insert_length,
 "coverage:s" => \$expect_cov,
 "read_length:s" => \$length_PE,
);

if ($fasta eq "" || $output1 eq "" || $output2 eq "") {
	print "\n\tUsage: $0 -fasta input_fasta_file -outfile1 fastq_read1_file -outfile2 fastq_read2_file -qual qual_value -insertlength insert_length(default 180) -coverage  expected_coverage(default 10) -read_length length_of_read(default 100)";
	print "\n\tExample: $0 -fasta contig.fa -outfile1 chopPseudo_R1.fastq -outfile2 chopPseudo_R2.fastq -qual_value 35 -insertlength 1000 -coverage 5 -read_length 80\n";
	exit(0);
}
print "Insert Length:\t$insert_length\n";
print "PE length:\t$length_PE\n";
# calculatethe step length
my $steplength = int($length_PE / ($expect_cov +1));
print "Step Length:\t$steplength\n";

my $infile = Bio::SeqIO->new(-file => "$fasta" ,  -format => 'Fasta');
my $oufile1 = Bio::SeqIO->new(-file => ">$output1", -format => "Fastq");
my $oufile2 = Bio::SeqIO->new(-file => ">$output2", -format => "Fastq");

while ( my $seqobj = $infile->next_seq() ) {
	my $seqlength = $seqobj->length();

    # for seqs length shorter than the insert length plus 2 timess PE_length, chop into PE_length.
	if ($seqlength < $insert_length + $expect_cov) {
		next;
	}

    #for seqs length longer than the insert length and shorter than two times insert length.
	elsif ($seqlength < $insert_length * 2) {
            my $steplength = int(($seqlength - $length_PE) / ($expect_cov + 1));
		#print the paired end seqs to the output file.  
            for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
                #my $seq = $seqobj->trunc($insert_length-$length_PE+$i,$insert_length+$i-1);
		my $seq1 = $seqobj->trunc($i+1 ,$length_PE+$i)->seq;
                my $seq2 = $seqobj->trunc($i+$insert_length-$length_PE+1,$i+$insert_length)->revcom->seq;
                $seq_nu++;
		my $a = $seq_id . $seq_nu;
	        my $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq1, -id => $a, -verbose => -1 );
                $oufile1->write_seq($qual_obj_write);
	        $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq2, -id => $a, -verbose => -1 );
                $oufile2->write_seq($qual_obj_write);
            }
            my $seq1 = $seqobj->trunc($seqlength-$insert_length + 1 ,$seqlength-$insert_length+$length_PE)->seq;
            my $seq2 = $seqobj->trunc($seqlength-$length_PE+1,$seqlength)->revcom->seq;
            $seq_nu++;
            my $a = $seq_id . $seq_nu;
	    my $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq1, -id => $a, -verbose => -1 );
            $oufile1->write_seq($qual_obj_write);
	    $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq2, -id => $a, -verbose => -1 );
            $oufile2->write_seq($qual_obj_write);
	}

	#for seqs length longer than two times insert length.
	else {
		#print the paired end seq to the output file
            for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
                #my $seq = $seqobj->trunc($insert_length-$length_PE+$i,$insert_length+$i-1);
		my $seq1 = $seqobj->trunc($i+1 ,$length_PE+$i)->seq;
                my $seq2 = $seqobj->trunc($i+$insert_length-$length_PE+1,$i+$insert_length)->revcom->seq;
                $seq_nu++;
		my $a = $seq_id . $seq_nu;
	        my $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq1, -id => $a, -verbose => -1 );
                $oufile1->write_seq($qual_obj_write);
	        $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq2, -id => $a, -verbose => -1 );
                $oufile2->write_seq($qual_obj_write);
            }
            my $seq1 = $seqobj->trunc($seqlength-$insert_length + 1 ,$seqlength-$insert_length+$length_PE)->seq;
            my $seq2 = $seqobj->trunc($seqlength-$length_PE+1,$seqlength)->revcom->seq;
            $seq_nu++;
            my $a = $seq_id . $seq_nu;
	    my $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq1, -id => $a, -verbose => -1 );
            $oufile1->write_seq($qual_obj_write);
	    $qual_obj_write = Bio::Seq::Quality->new( -qual => "$qual_value " x $length_PE, -seq => $seq2, -id => $a, -verbose => -1 );
            $oufile2->write_seq($qual_obj_write);
	}
}    
