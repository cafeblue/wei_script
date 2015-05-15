#! /bin/env perl

# Used to fetch the longest orfs from the getorf program.

# Writen by Wei Wang, Jan 07, 2010

use strict;
use Bio::SeqIO;

if (@ARGV < 2) {
	print "\n\tUsage; $0 infile outfile";
	print "\n\tExample: $0 transcripts.fa collapsed_transciptes.fasta\n";
#	print "\n\t\"number\" means the number of sequences you want to fetch from the input file.\n";
	exit(0);
}

my $infile =  Bio::SeqIO->new(-file => "$ARGV[0]", -format => "fasta");
my $outfile = Bio::SeqIO->new(-file => ">$ARGV[1]", -format => "fasta");
my $id = "0";
my $seq1;

while (my $seq_obj = $infile->next_seq()) {
	my $new_id = (split(/Transcript/, $seq_obj->display_id()))[0];
	if ($id eq "0") {
		$seq1 = $seq_obj;
		$id = $new_id;
	}
	elsif ($new_id ne $id) {
		$outfile->write_seq($seq1);
		$seq1 = $seq_obj;
		$id = $new_id;
	}
	else {
		if ($seq_obj->length() > $seq1->length()) {
			$seq1 = $seq_obj;
		}
	}
}

$outfile->write_seq($seq1);

	
