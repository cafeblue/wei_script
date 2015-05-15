#!/usr/bin/perl -w

# writen by Wang Wei Oct. 15 2009
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
my $start_length=250;
my $expect_cov=10;

&GetOptions
(
 "fasta:s" => \$fasta,
 "outfile:s" => \$output,
 "qual_value:s" => \$qual_value,
 "read_length:s" => \$start_length,
 "expect_cov:s" => \$expect_cov,
);

if ($fasta eq "" || $output eq "") {
	print "\n\tUsage: $0 -fasta input_fasta_file -outfile output_fasta_file -qual_value qual_value -read_length -reads_length(default 250) -expect_cov expected_coverage(default 10)";
	print "\n\tExample: $0 -fasta contig.fa -outfile chopPseudo.fasta -qual_value 40 -start_length 400 -expect_cov 10\n";
	exit(0);
}
print "Reads Length:\t$start_length\n";
print "Expected Coverage:\t$expect_cov\n";
my $steplength = int($start_length / ($expect_cov + 1));
print "Step Length:\t$steplength\n";

my $infile = Bio::SeqIO->new(-file => "$fasta" ,  -format => 'Fasta');
my $outfile = Bio::SeqIO->new(-file => ">$output" ,  -format => 'Fasta');

while ( my $seqobj = $infile->next_seq() ) {
	my $seqlength = $seqobj->length();

    # for seqs length short than the start_length, print to the result file directly expected coverage times.
    if ($seqlength < $start_length + $expect_cov + 1) {
		for (my $i=0; $i<$expect_cov; $i++) {
			my $seq = $seqobj->seq(); 
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			my $length_tmp = int($start_length/2);
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
			if (length($seq) >= 50) {
		        my $seqNew = Bio::Seq->new(-seq => $seq,
    		         -display_id => $seqobj->display_id()."_short_".$i, -alphabet => 'dna');
        		$outfile->write_seq($seqNew);
			}
		}
    }

    #for seqs length longer than the start length and shorter than two times start length.
	else {
		if ($seqlength < $start_length * 2) {
			$steplength = int(($seqlength - $start_length) / ($expect_cov + 1));
		}
		#pring the first *$expect_cov seqs and last *$expect_cov seqs to the output file.
		for (my $i = 0; $i < $expect_cov; $i++){
			my $seq = $seqobj->subseq(1, $start_length);
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			my $length_tmp = int($start_length/2);
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
			if (length($seq) >= 50) {
				my $seqNew = Bio::Seq->new(-seq => $seq,
    	                 -display_id => $seqobj->display_id()."_head_$i", -alphabet => 'dna' );
				$outfile->write_seq($seqNew);
			}
            #my $seqNew1 = Bio::Seq->new(-seq => $seqobj->subseq($start_point, 
            #    $seqlength-(4-$i)*$steplength).$iseq, -display_id => $seqobj->display_id()."_tail_$i", 
            #    -alphabet => 'dna' );
			$seq = $seqobj->subseq(($seqlength - $start_length), $seqlength);
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			$length_tmp = int($start_length/2);
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
			if (length($seq) >= 50) {
	            my $seqNew1 = Bio::Seq->new(-seq => $seq
    	            , -display_id => $seqobj->display_id()."_tail_$i", 
        	        -alphabet => 'dna' );
            	$outfile->write_seq($seqNew1);
			}
		}
		#print the paired end seq to the output file
		for (my $i = 0; $i+$start_length < $seqlength; $i+=$steplength) {
			my $seq = $seqobj->subseq(1+$i, $i + $start_length);
			$seq =~ s/^N{1,}//ig;
			$seq =~ s/N{1,}$//ig;
			my $length_tmp = int($start_length/2);
			if ($seq  =~ /(N{$length_tmp,})/) {
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
			if (length($seq) >= 50) {
	            my $seqNew = Bio::Seq->new(-seq => $seq,
    	            -display_id => $seqobj->display_id()."_PE_$i", -alphabet => 'dna' );
        	    $outfile->write_seq($seqNew);
			}
		}
		if ($seqlength < $start_length * 2) {
            $steplength = int($start_length / ($expect_cov + 1));
        }
	}
}    

my $cmd = "form_qual_for_fasta.pl $output $qual_value";
system($cmd);
