#!/usr/bin/perl -w

use strict;
use warnings;

my $in = $ARGV[0];
my $out = $ARGV[1];
die "Usage:	$0 \$InputFile_*.psl \$OutputFile_result.txt\n" if(@ARGV != 2);

open IN, "$in" or die $!;
open OUT, ">$out" or die $!;

my %hasharray;

while (<IN>){
	chomp;
	if (/(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t\S\t(\S+)\t(\d+)\t(\d+)\t(\d+)\t(\S+)\t(\d+)\t(\d+)\t(\d+)/){
		if (exists($hasharray{$13})){
			for (my $i=($15 + 1); $i<=($16 + 1); $i++){
				$hasharray{$13}[$i]++;
			}
#			print "@{$hasharray{$13}}\n"
		}else{
			my @count;
			for (my $i=0; $i<$14; $i++){
				$count[$i] = 0;
			}
			unshift @count, $14;
			for (my $i=($15 + 1) ; $i<=($16 + 1); $i++){
				$count[$i]++;
			}
			$hasharray{$13} = [@count];
#			print "@{$hasharray{$13}}\n";
		}
	}
}

print OUT "contigID\t#mappedBases\tcontigLength\n";
my $mappedSize = 0;
my $totalSize = 0;
foreach my $contig (sort keys %hasharray) {
	my $countCov = 0;
	$totalSize=$totalSize+$hasharray{$contig}[0];
	for (my $i=1; $i<=$hasharray{$contig}[0]; $i++){
		if ($hasharray{$contig}[$i] > 0){
			$countCov++;
			$mappedSize++;
#			$totalSize=+$hasharray{};
		}
	}
#	unshift
	print OUT "$contig\t$countCov\t$hasharray{$contig}[0]\n";
#	print "$hasharray{$contig}}"
}
print OUT "Mapped Total Size: $mappedSize\n";
print OUT "Contig Total Size: $totalSize\n";