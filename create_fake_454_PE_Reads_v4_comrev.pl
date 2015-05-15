#!/usr/bin/perl -w

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
	return join("", @chars[ map { rand @chars } ( 1 .. 12 ) ]);
}

my $fasta="";
my $qual_value=40;
my $output="";
my $insert_length = 8000;
my $length_PE = 100;
my $expect_cov = 10;  # expected coverage

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
open (OUTP, ">$output") or die $!;

while ( my $seqobj = $infile->next_seq() ) {
	my $seqlength = $seqobj->length();

    # for seqs length shorter than the insert length plus 2 timess PE_length, chop into PE_length.
	if ($seqlength < ($insert_length + $expect_cov)) {
		next;
	}

    #for seqs length longer than the insert length and shorter than two times insert length.
	elsif ($seqlength < $insert_length * 2 + $length_PE) {
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
			$seq_tmp = reverse($seq_tmp);
			$seq_tmp =~ tr/ATGCatgc/TACGtacg/;
			if (length($seq) >= 15 && length($seq_tmp) >= 15) { 
				my $a = random();
				print OUTP ">",$a,'.r1',"\n";
				print OUTP $seq,"\n";
				print OUTP ">",$a,'.f1',"\n";
				print OUTP $seq_tmp,"\n";
			}
		}
	}

	#for seqs length longer than two times insert length.
	else {
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
			$seq_tmp = reverse($seq_tmp);
			$seq_tmp =~ tr/ATGCatgc/TACGtacg/;
			if (length($seq) >= 15 && length($seq_tmp) >= 15) { 
				my $a = random();
				print OUTP ">",$a,'.r1',"\n";
				print OUTP $seq,"\n";
				print  OUTP ">",$a,'.f1',"\n";
				print OUTP $seq_tmp,"\n";
			}
		}
	}
}    

my $cmd = "form_qual_for_fasta.pl $output $qual_value";
system($cmd);
