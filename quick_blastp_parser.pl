#! /usr/bin/perl -w

use strict;
use Bio::SearchIO;

if (@ARGV < 2) {
	print "\n\tUsage: $0 input_blast_file output_table\n";
	exit(0);
}

open (OUF, ">$ARGV[1]") or die $!;
my $searchio = Bio::SearchIO->new(-format => 'blast', -file   => "$ARGV[0]");

while( my $result = $searchio->next_result ) {
	if ($result->num_hits == 0) {
		print OUF $result->query_name(),"\tNoHit!!\n";
		next;
	}
	my $query_name = $result->query_name();
	my $best_hit_acc = "";
	my $best_hit_desc = "";
	my $best_hit_eval = "";
	my $best_knownhit_acc = "";
	my $best_knownhit_desc = "";
	my $best_knownhit_eval = "";
	my $flag = 0;
	while( my $hit = $result->next_hit ) {
		if ($best_hit_acc eq "") {
			$best_hit_acc = $hit->accession();
			$best_hit_desc = $hit->hit_description();
		}
		if (not ($hit->hit_description() =~ /(predicted)|(unknown)|(hypotheti)|(putative)/i)) {
			$best_knownhit_acc = $hit->accession();
			$best_knownhit_desc = $hit->hit_description();
			$flag++;
		}
		while( my $hsp = $hit->hsp()) {
			if ($best_hit_eval eq "") {
				$best_hit_eval = $hsp->evalue();
			}
			if ($flag == 1) {
				$best_knownhit_eval = $hsp->evalue();
			}
			last;
		}
		if ($flag == 1) {
			last;
		}
	}

	print OUF $query_name,"\t",$best_hit_acc,"\t",$best_hit_desc,"\t",$best_hit_eval,"\t",$best_knownhit_acc,"\t",$best_knownhit_desc,"\t",$best_knownhit_eval,"\n";
}

