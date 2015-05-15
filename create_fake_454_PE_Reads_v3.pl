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
my $length_PE = 100;
my $expect_cov = 10;  # expected coverage
#my $iseq = "TCGTATAACTTCGTATAATGTATGCTATACGAAGTTATTACG";
my $iseq = "GTTGGAACCGAAAGGGTTTGAATTCAAACCCTTTCGGTTCCAAC";

&GetOptions
(
 "fasta:s" => \$fasta,
 "outfile:s" => \$output,
 "qual:s" => \$qual_value,
 "insertlength:s" => \$insert_length,
 "coverage:s" => \$expect_cov,
 "PE_length:s" => \$length_PE,
);

if ($fasta eq "" || $output eq "") {
	print "\n\tUsage: $0 -fasta input_fasta_file -outfile output_fasta_file -qual qual_value -insertlength insert_length(default 8000) -coverage  expected_coverage(default 10) -PE_length length_of_each_PE_termianl(default 100)";
	print "\n\tExample: $0 -fasta contig.fa -outfile chopPseudo.fasta -qual_value 40 -insertlength 2000 -coverage 10 -PE_length 200\n";
	exit(0);
}
print "Insert Length:\t$insert_length\n";
print "PE length:\t$length_PE\n";
# calculatethe step length
my $steplength = int($length_PE / ($expect_cov +1));
print "Step Length:\t$steplength\n";

my $infile = Bio::SeqIO->new(-file => "$fasta" ,  -format => 'Fasta');
my $outfile = Bio::SeqIO->new(-file => ">$output" ,  -format => 'Fasta');

while ( my $seqobj = $infile->next_seq() ) {
	my $seqlength = $seqobj->length();

    # for seqs length short than the start_length, print to the result file directly.
#    if ($seqlength <= $length_PE + $expect_cov) {
#		for (my $i = 0; $i < $expect_cov; $i++) {
#        	my $seqNew = Bio::Seq->new(-seq => $seqobj->seq().$iseq,
#    	         -display_id => $seqobj->display_id()."_singlei_".$i, -alphabet => 'dna');
#	        $outfile->write_seq($seqNew);
#		}
#    }

    # for seqs length shorter than the insert length plus 2 timess PE_length, chop into PE_length.
	if ($seqlength < ($insert_length + $expect_cov)) {
		next;
#		my $my_own_step = int(($seqlength - $length_PE) / ($expect_cov + 1));
#		if ($my_own_step > $steplength) {
#			$my_own_step = $steplength;
#		}
#		elsif ($my_own_step <= 0) {
#			print "My Own Step is $my_own_step, Something Wrong?\n";
#			print "seq length: $seqlength\t id: $seqobj->display_id()\n";
#			print "Insert length: $insert_length\t expected coverage: $expect_cov\n";
#			exit(0);
#		}
#		for (my $i = 0; $i <= $expect_cov; $i++) {
#			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq(1, $length_PE).$iseq,
#               -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
#            $outfile->write_seq($seqNew);
#            my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($seqlength - $length_PE, $seqlength).$iseq,
#                -display_id => $seqobj->display_id()."_tail_$i", -alphabet => 'dna' );
#            $outfile->write_seq($seqNew1);
#		}
#        for (my $i = 1; $i <= $seqlength; $i += $my_own_step) {
#            if ($seqlength-$i < $length_PE) {
#                my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i, $seqlength).$iseq,
#                     -display_id => $seqobj->display_id()."_chop_$i", -alphabet => 'dna' );
#                $outfile->write_seq($seqNew);
#                last;
#            }
#    		my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($i, $i+$length_PE).$iseq,
#                -display_id => $seqobj->display_id()."_chop_$i", -alphabet => 'dna' );
#            $outfile->write_seq($seqNew);
#        }
	}

    #for seqs length longer than the insert length and shorter than two times insert length.
	elsif ($seqlength < $insert_length * 2 + $length_PE) {
#		my $middle_seq_start_position;
#		my $middle_seq_stop_position = $insert_length-$length_PE;
		#pring the first 5 seqs and last 5 seqs to the output file.
#		for (my $i = 0; $i <= $expect_cov; $i++){
#			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq(1, $length_PE).$iseq,
#                     -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
#			$outfile->write_seq($seqNew);
#            my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($seqlength - $length_PE, 
#                $seqlength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
#                -alphabet => 'dna' );
#            $outfile->write_seq($seqNew1);
#		}
		#print the paired end seqs to the output file.  
        for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
            my $seq = $seqobj->subseq($insert_length-$length_PE+$i,$insert_length+$i-1);
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			my $length_tmp = int($length_PE/2);
			if ($seq =~ /(N{$length_tmp,})/) {
				my @tmp = split(/$1/, $seq);
				if (@tmp > 2) {
					print "Something Wrong?\n";
				}
				elsif (length($tmp[0]) > length($tmp[1])) {
					$seq = $tmp[0];
				}
				else {
					$seq = $tmp[1];
				}	
			}
			$seq .= $iseq;
			my $seq_tmp = $seqobj->subseq(1+$i,$length_PE+$i);
			$seq_tmp =~ s/^N{1,}//ig;
			$seq_tmp =~ s/N{1,}$//ig;
			if ($seq_tmp =~ /(N{$length_tmp,})/) {
				my @tmp = split(/$1/, $seq_tmp);
				if (@tmp > 2) {
					print "Something Wrong?\n";
				}
				elsif (length($tmp[0]) > length($tmp[1])) {
					$seq_tmp = $tmp[0];
				}
				else {
					$seq_tmp = $tmp[1];
				}	
			}
			$seq .= $seq_tmp;
#			$middle_seq_start_position = $length_PE+$i;
            my $seqNew = Bio::Seq->new(-seq => $seq,
                -display_id => $seqobj->display_id()."_PE_$i", -alphabet => 'dna' );
            $outfile->write_seq($seqNew);
		}
		#print the middle seqs which could not be covered by paired end seqs to the 
#		if ($middle_seq_stop_position<$middle_seq_start_position) {
#			my $middle_position = int(($middle_seq_start_position - $middle_seq_stop_position)/2) + $middle_seq_stop_position;
#			my $my_own_step = int($length_PE/2);
#			for (my $i = 0; $i < $expect_cov; $i++) {
#				my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_position - $my_own_step,
#					$middle_position + $my_own_step).$iseq, -display_id => $seqobj->display_id()."_middle_cross".$i,
#					-alphabet => 'dna' );
#				$outfile->write_seq($seqNew);
#			}
#		}
#		else {
#			for (my $i=0; $i + $middle_seq_start_position - $length_PE < $middle_seq_stop_position ; $i += $steplength){
#				my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq($middle_seq_start_position - $length_PE + $i, 
#					$middle_seq_start_position + $i).$iseq, 
#					-display_id => $seqobj->display_id()."_middle_$i",
#					-alphabet => 'dna' );
#				$outfile->write_seq($seqNew);
#			}
#		}
	}

	#for seqs length longer than two times insert length.
	else {
		#print the first 5 seqs and last 5 seqs to the output file.
#		for (my $i = 0; $i <= $expect_cov; $i++){
#			my $seqNew = Bio::Seq->new(-seq => $seqobj->subseq(1, $length_PE).$iseq,
#                     -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
#			$outfile->write_seq($seqNew);
#            my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($seqlength - $length_PE,
#					 $seqlength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
#					 -alphabet => 'dna' );
            #my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point,
			#		 $seqlength-(4-$i)*$steplength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
			#		 -alphabet => 'dna' );
#            $outfile->write_seq($seqNew1);
#		}

		#print the paired end seq to the output file
		for (my $i = 0; $i+$insert_length < $seqlength; $i+=$steplength) {
            my $seq = $seqobj->subseq($insert_length-$length_PE+$i,$insert_length+$i-1);
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			my $length_tmp = int($length_PE/2);
			if ($seq =~ m/(N{$length_tmp,})/) {
				my @tmp = split(/$1/, $seq);
				if (@tmp > 2) {
					print "Something Wrong?\n";
				}
				elsif (length($tmp[0]) > length($tmp[1])) {
					$seq = $tmp[0];
				}
				else {
					$seq = $tmp[1];
				}	
			}
			$seq .= $iseq;
			my $seq_tmp = $seqobj->subseq(1+$i,$length_PE+$i);
			$seq_tmp =~ s/^N{1,}//ig;
			$seq_tmp =~ s/N{1,}$//ig;
			if ($seq_tmp =~ /(N{$length_tmp,})/) {
				my @tmp = split(/$1/, $seq_tmp);
				if (@tmp > 2) {
					print "Something Wrong?\n";
				}
				elsif (length($tmp[0]) > length($tmp[1])) {
					$seq_tmp = $tmp[0];
				}
				else {
					$seq_tmp = $tmp[1];
				}	
			}
			$seq .= $seq_tmp;
            my $seqNew = Bio::Seq->new(-seq => $seq,
                -display_id => $seqobj->display_id()."_PE_$i", -alphabet => 'dna' );
            $outfile->write_seq($seqNew);
		}
	}
}    

my $cmd = "form_qual_for_fasta.pl $output $qual_value";
system($cmd);
