#!/usr/bin/perl -w

# writen by Wang Wei sep. 11 2009
#
# this script used to chop the long seqs into 
# high coverage short pseudo reads.

use strict;
use Getopt::Long;
use Bio::Seq;
use Bio::SeqIO;

my $fasta="";
my $qual_value=40;
my $output="";
my $insert_length = 8000;
my $start_length=250;
my $steplength=200;
my $length_PE = 800;
my $iseq = "TCGTATAACTTCGTATAATGTATGCTATACGAAGTTATTACG";
#my $coverages="";

&GetOptions
(
 "fasta:s" => \$fasta,
 "outfile:s" => \$output,
 "qual_value:s" => \$qual_value,
 "insertlength:s" => \$insert_length,
 "start_length:s" => \$start_length,
 "steplength:s" => \$steplength,
 "PE_length:s" => \$length_PE,
);

if ($fasta eq "" || $output eq "") {
	print "\n\tUsage: $0 -fasta input_fasta_file -outfile output_fasta_file -qual_value qual_value -insertlength insert_length(default 8000) -start_length min_reads_length(default 250) -steplength length_of_each_steps(default 200) -PE_length length_of_each_PE_termianl(default 800)";
	print "\n\tExample: $0 -fasta contig.fa -outfile chopPseudo.fasta -qual_value 40 -insertlength 2000 -start_length 400 -steplength 100 -PE_length 800\n";
	exit(0);
}
print "Insert_length:\t$insert_length\n";
print "Start_length:\t$start_length\n";
print "Step_length:\t$steplength\n";
print "Length_PE:\t$length_PE\n";

my $infile = Bio::SeqIO->new(-file => "$fasta" ,  -format => 'Fasta');
my $outfile = Bio::SeqIO->new(-file => ">$output" ,  -format => 'Fasta');

while ( my $seqobj = $infile->next_seq() ) {
	my $seqlength = $seqobj->length();

    # for seqs length short than the start_length, print to the result file directly.
    if ($seqlength < $start_length) {
        my $seqNew = Bio::Seq->new(-seq => $seqobj->seq().$iseq,
             -display_id => $seqobj->display_id()."_single", -alphabet => 'dna');
        $outfile->write_seq($seqNew);
    }

    # for seqs length shorter than the insert length plus 2 timess PE_length, chop into PE_length.
	elsif ($seqlength < ($insert_length + $length_PE * 2)) {
        for (my $i = 1; $i <= $seqlength; $i += $steplength) {
            if ($seqlength-$i < $length_PE) {
                my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i, $seqlength).$iseq,
                     -display_id => $seqobj->display_id()."_chop_$i", -alphabet => 'dna' );
                $outfile->write_seq($seqNew);
                last;
            }
    		my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i, $i+$length_PE).$iseq,
                -display_id => $seqobj->display_id()."_chop_$i", -alphabet => 'dna' );
            $outfile->write_seq($seqNew);
        }
	}

    #for seqs length longer than the insert length and shorter than two times insert length.
	elsif ($seqlength < $insert_length * 2) {
		my $middle_seq_start_position;
		my $middle_seq_stop_position = $insert_length-$length_PE+50;
		#pring the first 5 seqs and last 5 seqs to the output file.
		for (my $i = 0; $i <= 4; $i++){
            my $end_point = $start_length + $steplength*$i;
            my $start_point = $seqlength - (4-$i)*$steplength - $start_length;
			#my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i*$steplength+1, $end_point).$iseq,
            #         -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq(1, $end_point).$iseq,
                     -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
			$outfile->write_seq($seqNew);
            #my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point, 
            #    $seqlength-(4-$i)*$steplength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
            #    -alphabet => 'dna' );
            my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point, 
                $seqlength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
                -alphabet => 'dna' );
            $outfile->write_seq($seqNew1);
		}
		#print the paired end seqs to the output file.  
        for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
            my $seq = $seqobj->subseq($insert_length-$length_PE+$i,$insert_length+$i-1);
			$seq .= $iseq;
			$seq .= $seqobj->subseq(1+$i,$length_PE+$i);
			$middle_seq_start_position = $length_PE+$i-50;
            my $seqNew = Bio::Seq->new(-seq => $seq,
                -display_id => $seqobj->display_id()."_PE_$i", -alphabet => 'dna' );
            $outfile->write_seq($seqNew);
		}
		#print the middle seqs which could not be covered by paired end seqs to the 
		if ($middle_seq_stop_position<$middle_seq_start_position) {
			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_seq_stop_position-25,
				$middle_seq_start_position+25).$iseq,-display_id => $seqobj->display_id()."_middle_cross",
				-alphabet => 'dna' );
			$outfile->write_seq($seqNew);
		}
		elsif ($middle_seq_stop_position-$middle_seq_start_position < $length_PE) {
			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_seq_start_position, 
				$middle_seq_stop_position).$iseq, -display_id => $seqobj->display_id()."_middle", 
				-alphabet => 'dna' );
			$outfile->write_seq($seqNew);
		}
		else {
			for (my $i=0; $i+$length_PE+$middle_seq_start_position < $middle_seq_stop_position; $i+=$steplength){
				my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_seq_start_position+$i, 
					$middle_seq_start_position+$length_PE+$i).$iseq, 
					-display_id => $seqobj->display_id()."_middle_$i",
					-alphabet => 'dna' );
				$outfile->write_seq($seqNew);
			}
			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_seq_stop_position-$length_PE, 
				$middle_seq_stop_position).$iseq, -display_id => $seqobj->display_id()."_middle_end",
				-alphabet => 'dna' );
			$outfile->write_seq($seqNew);
		}
	}

	#for seqs length longer than two times insert length.
	else {
		#print the first 5 seqs and last 5 seqs to the output file.
		for (my $i = 0; $i <= 4; $i++){
            my $end_point = $start_length + $steplength*$i;
            my $start_point = $seqlength - (4-$i)*$steplength - $start_length;
			#my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i*$steplength+1, $end_point).$iseq,
            #         -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq(1, $end_point).$iseq,
                     -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
			$outfile->write_seq($seqNew);
            my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point,
					 $seqlength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
					 -alphabet => 'dna' );
            #my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point,
			#		 $seqlength-(4-$i)*$steplength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
			#		 -alphabet => 'dna' );
            $outfile->write_seq($seqNew1);
		}

		#print the paired end seq to the output file
		for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
            my $seq = $seqobj->subseq($insert_length-$length_PE+$i,$insert_length+$i-1);
			$seq .= $iseq;
			$seq .= $seqobj->subseq(1+$i,$length_PE+$i);
            my $seqNew = Bio::Seq->new(-seq => $seq,
                -display_id => $seqobj->display_id()."_PE_$i", -alphabet => 'dna' );
            $outfile->write_seq($seqNew);
		}
	}
}    

my $cmd = "form_qual_for_fasta.pl $output $qual_value";
system($cmd);
