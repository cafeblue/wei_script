#! /usr/bin/perl -w

# used to find out the bridge region.
# column 1: contig1;
# column 2: contig2;
# column 3: number of pairs;
# column 4,5: position region mapped of contig1;
# column 6,7: position region mapped of contig2;

# writen by Wei Wang Mar. 17 2010;

use strict;

my %pair_count;
my %se_1;
my %se_2;
my $pair_name;

if (@ARGV < 2) {
	print "\n\tUsage: $0 input_aln output_file";
	print "\n\tExample: $0 0723_maq_sorted.aln bridge.list\n";
	exit(0);
}

open (INF, "$ARGV[0]") or die $!;
open (OUF, ">$ARGV[1]") or die $!;
my $id1;
my $id2;
my $line_check;
my $pos1;
my $pos2;

while (<INF>) {
	my ($reads, $contig, $pos, $flag) = (split(/\t/, $_))[0,1,2,5];
	if ($reads =~ /0\/1$/ && $flag == 32) {
		$id1 = $contig;
		$pos1 = $pos;
		$line_check = $.;
		next;
	}
	if ($reads =~/0\/2$/ && $flag == 32) {
		if ($.-$line_check != 1) {
			die "not sorted!\n";
			exit(0);
		}
		$id2 = $contig;
		$pos2 = $pos;
		$pair_name = join('___', sort($id1,$id2));
		if (exists $pair_count{$pair_name}) {
			$pair_count{$pair_name}++;
		}

		if ($id1 eq (split(/\_\_\_/, $pair_name))[0]) {
			if (exists $pair_count{$pair_name}) {
				$se_1{$pair_name} .= "_$pos1";
				$se_2{$pair_name} .= "_$pos2";
			}
			else {
				$pair_count{$pair_name} = 1;
				$se_1{$pair_name} = "$pos1";
				$se_2{$pair_name} = "$pos2";
			}
		}
		elsif ($id1 eq (split(/\_\_\_/, $pair_name))[1]) {
			if (exists $pair_count{$pair_name}) {
				$se_1{$pair_name} .= "_$pos2";
				$se_2{$pair_name} .= "_$pos1";
			}
			else {
				$pair_count{$pair_name} = 1;
				$se_2{$pair_name} = "$pos1";
				$se_1{$pair_name} = "$pos2";
			}
		}
		else {
			die "Something Wrong?\n";
		}
	}
}

foreach ( sort{ $pair_count{$b} <=> $pair_count{$a}} keys %pair_count) {
	my $cont_nam = $_;
	my ($ida, $idb) = split(/\_\_\_/, $_);
	my $length_a = (split('_', $ida))[2];
	my $length_b = (split('_', $idb))[2];
	my $term_5 = 0;
	my $term_3 = 0;
	my $term_0 = 0;
	print OUF $ida,"\t",$idb,"\t";
	print OUF $pair_count{$cont_nam},"\t";
	my @pos1_list = split('_', $se_1{$cont_nam});
	my @pos2_list = split('_', $se_2{$cont_nam});
	foreach (@pos1_list) {
		if ($_<300) {
			$term_5++;
		}
		elsif ($length_a - $_ < 300) {
			$term_3++;
		}
		else {
			$term_0++;
		}
	}

	print OUF $term_5,"\t",$term_3,"\t",$term_0,"\t";
	if ($term_0 >= $term_5 && $term_0 >= $term_3) {
		my $p = sprintf("%5.2f", $term_0*100/($term_0+$term_5+$term_3));
		print OUF "NULL_$p\t";
	}
	elsif ($term_5 > $term_3) {
		my $p = sprintf("%5.2f", $term_5*100/($term_0+$term_5+$term_3));
		print OUF "term5_$p\t";
	}
	else {
		my $p = sprintf("%5.2f", $term_3*100/($term_0+$term_5+$term_3));
		print OUF "term3_$p\t";
	}
	$term_5 = $term_3 = $term_0 = 0;
	foreach (@pos2_list) {
		if ($_<300) {
			$term_5++;
		}
		elsif ($length_a - $_ < 300) {
			$term_3++;
		}
		else {
			$term_0++;
		}
	}

	print OUF $term_5,"\t",$term_3,"\t",$term_0,"\t";
	if ($term_0 >= $term_5 && $term_0 >= $term_3) {
		my $p = sprintf("%5.2f", $term_0*100/($term_0+$term_5+$term_3));
		print OUF "NULL_$p\n";
	}
	elsif ($term_5 > $term_3) {
		my $p = sprintf("%5.2f", $term_5*100/($term_0+$term_5+$term_3));
		print OUF "term5_$p\n";
	}
	else {
		my $p = sprintf("%5.2f", $term_3*100/($term_0+$term_5+$term_3));
		print OUF "term3_$p\n";
	}
}
