#! /usr/bin/perl -w

# Used to fetch the longest orfs from the getorf program.

# Writen by Wei Wang, Jan 07, 2010

use strict;
use Bio::SeqIO;

if (@ARGV < 2) {
	print "\n\tUsage; $0 infile outfile";
	print "\n\tExample: $0 getorf.pep pep.fasta\n";
#	print "\n\t\"number\" means the number of sequences you want to fetch from the input file.\n";
	exit(0);
}

my $infile =  Bio::SeqIO->new(-file => "$ARGV[0]", -format => "fasta");
my $outfile = Bio::SeqIO->new(-file => ">$ARGV[1]", -format => "fasta");
my $id = "0";
my $seq1;
my $seq2;

while (my $seq_obj = $infile->next_seq()) {
	my $new_id = (split(/\s/, $seq_obj->display_id()))[0];
	$new_id =~ s/\_\d+$//;
	if ($id eq "0") {
		$seq1 = $seq_obj;
		$id = $new_id;
	}
	elsif ($new_id ne $id) {
		if ($seq1->length() == $seq2->length()) {
			$outfile->write_seq($seq1);
			$outfile->write_seq($seq2);
			print "Identical Length: ", $seq1->display_id(),"\t", $seq2->display_id(),"\n";
		}
		else {
			$outfile->write_seq($seq1);
		}
		$seq1 = $seq_obj;
		$id = $new_id;
	}
	else {
		if ($seq_obj->length() >= $seq1->length()) {
			$seq2 = $seq1;
			$seq1 = $seq_obj;
		}
		elsif ($seq_obj->length() >= $seq2->length()) {
			$seq2 = $seq_obj;
		}
	}
}

if ($seq1->length() == $seq2->length()) {
    $outfile->write_seq($seq1);
    $outfile->write_seq($seq2);
    print "Identical Length: ", $seq1->display_id(),"\t", $seq2->display_id(),"\n";
}
else {
    $outfile->write_seq($seq1);
}

	
