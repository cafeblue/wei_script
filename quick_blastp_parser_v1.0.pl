#! /usr/bin/perl -w

use strict;
use Bio::SearchIO;

if (@ARGV < 2) {
	print "\n\tUsage: $0 input_blast_file type(nr/kegg) output_table";
	print "\n\tExample: $0 nanno2kegg_e-5.blastp kegg nanno2kegg.xls\n";
	exit(0);
}

open (OUF, ">$ARGV[2]") or die $!;
my $searchio = Bio::SearchIO->new(-format => 'blast', -file   => "$ARGV[0]");

my $link = '=HYPERLINK("http://';
my %ko2pathway;
my $path_link = '=HYPERLINK("http://www.genome.jp/kegg-bin/show_pathway?';
if ($ARGV[1] eq "nr") {
	$link .= 'www.ncbi.nlm.nih.gov/protein/';
}
elsif ($ARGV[1] eq "kegg") {
	$link .= 'www.genome.jp/dbget-bin/www_bget?';
	open (KO, "/home/gene/bioinfo/data/bio_databases/kegg/ko.list") or die $!;
	while (<KO>) {
		my ($path_id, $ko_id) = (split(/\t/, $_))[0,1];
		if ($path_id =~ /path\:(.+)/) {
			$path_id = $1;
			if ($ko_id =~ /ko\:/) {
				if (exists $ko2pathway{$ko_id}) {
					$ko2pathway{$ko_id} .= "\t$path_id";
				}
				else {
					$ko2pathway{$ko_id} = "$path_id";
				}
			}
		}
	}
}
else {
	print "\n\ttype should be \"nr\" or \"kegg\"\n";
	print "\tother types are to be developed...\n";
	exit(0);
}

while( my $result = $searchio->next_result ) {
	if ($result->num_hits == 0) {
		print OUF $result->query_name(),"\tNoHit!!\n";
		next;
	}
	my $query_name = $result->query_name();
	my $best_hit_acc = "";
	my $best_hit_desc = "";
	my $best_hit_pval = "";
	my $best_knownhit_acc = "";
	my $best_knownhit_desc = "";
	my $best_knownhit_eval = "";
	my $flag = 0;
	while( my $hit = $result->next_hit ) {
		if ($best_hit_acc eq "") {
			$best_hit_acc = $hit->accession();
			$best_hit_acc = $link.$best_hit_acc.'","'.$best_hit_acc.'")';
			$best_hit_desc = $hit->hit_description();
			$best_hit_pval = $hit->expect();
		}
		if ($hit->hit_description() =~ /\001/) {
			my @hits = split(/\001/, $hit->hit_description());
			foreach(@hits) {
				if (not /(unknown)|(hypotheti)|(predicted)/i) {
					$best_knownhit_acc = $hit->accession();
					$best_knownhit_acc = $link.$best_knownhit_acc.'","'.$best_knownhit_acc.'")';
					$best_knownhit_desc = $hit->hit_description();
					$best_knownhit_eval = $hit->expect();
					$flag++;
					last;
				}
			}
		}
		else {
			if (not ($hit->hit_description() =~ /(unknown)|(hypotheti)|(predicted)/i)) {
				$best_knownhit_acc = $hit->accession();
				$best_knownhit_desc = $hit->hit_description();
				$best_knownhit_eval = $hit->expect();
				$flag++;
			}
		}
		if ($flag == 1) {
			last;
		}
	}
	if ($ARGV[1] eq "kegg") {
		my $best_knownko = 'NO KO Number!';
		my $best_ko = 'NO KO Number!';
		my $best_path = "NO Pathway";
		my $best_path_other = "No other Pathway";
		my $best_knownpath = "NO Pathway";
		my $best_knownpath_other = "No other Pathway";
		if ($best_hit_desc =~ /(K\d{5})/) {
			my $tmp_ko = $1;
			$tmp_ko = 'ko:' . $tmp_ko;
			$best_ko = $link . $tmp_ko . '","' . $tmp_ko . '")';
			if (exists $ko2pathway{$tmp_ko}) {
				$best_path = (split(/\t/, $ko2pathway{$tmp_ko}))[0];
				$best_path = $path_link . $best_path . '","' . $best_path . '")';
				if ($ko2pathway{$tmp_ko} =~ /\t/) {
					my $best_path_other = $ko2pathway{$tmp_ko};
					$best_path_other =~ s/^.+?\t//;
					$best_path_other =~ s/\t/,/;
				}
			}
		}
		if ($best_knownhit_desc =~ /(K\d{5})/) {
			my $tmp1_ko = $1;
			$tmp1_ko = 'ko:' . $tmp1_ko;
			$best_knownko = $link . $tmp1_ko . '","' . $tmp1_ko . '")';
			if (exists $ko2pathway{$tmp1_ko}) {
				$best_knownpath = (split(/\t/, $ko2pathway{$tmp1_ko}))[0];
				$best_knownpath = $path_link . $best_knownpath . '","' . $best_knownpath . '")';
				if ($ko2pathway{$tmp1_ko} =~ /\t/) {
					$best_knownpath_other = $ko2pathway{$tmp1_ko};
					$best_knownpath_other =~ s/^.+?\t//;
					$best_knownpath_other =~ s/\t/,/;
				}
			}
		}
		print OUF $query_name,"\t",$best_hit_acc,"\t",$best_hit_desc,"\t",$best_hit_pval,"\t",$best_ko,"\t",$best_path,"\t",$best_path_other,"\t",$best_knownhit_acc,"\t",$best_knownhit_desc,"\t",$best_knownhit_eval,"\t",$best_knownko,"\t",$best_knownpath,"\t",$best_knownpath_other,"\n";
		
	}
	elsif ($ARGV[1] eq "nr") {
		print OUF $query_name,"\t",$best_hit_acc,"\t",$best_hit_desc,"\t",$best_hit_pval,"\t",$best_knownhit_acc,"\t",$best_knownhit_desc,"\t",$best_knownhit_eval,"\n";
	}
}

