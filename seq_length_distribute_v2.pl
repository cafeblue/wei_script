#! /bin/env perl
#Wei Wang

# four parameters
# the first is the input fasta file;
# the second is the length of the largest contig.
# the third is the length of the steps.
# the output is the out file name
use strict;
use Bio::SeqIO;

if ($ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "" || $ARGV[3] eq "") {
	print "\n\tUsage $0 inputfile length length outputfile\n";
	print "\t Example $0 454AllContigs.fna 62000 5000 output.xls\n";
	exit(0);
}

my $infile = Bio::SeqIO->new(-file => "$ARGV[0]" ,  -format => 'Fasta');
open (OUTPUT, ">$ARGV[3]") || die $!;

my $largest = $ARGV[1];
my $steps = $ARGV[2];

#$largest =~ s/k//;
#$steps =~ s/k//;

my @edges = ();
my %bin;
my $number_steps = 0;
my $total_contigs = 0;
my $total_contigs1 = 0;

while ($largest >= 0) {
	$number_steps++;
	@edges = (@edges, $largest);
	$largest -= $steps;
}
$number_steps++;
@edges = (@edges, 0);

while (my $seqobj = $infile->next_seq()) {
	$total_contigs++;
	my $length = $seqobj->length;
#	if ($length < $edges[$number_steps-1]) {
#		if (exists $bin{$number_steps}) {
#			$bin{$number_steps}++;
#		}
#		else {
#			$bin{$number_steps} = 1;
#		}
#	}
#	else {
		for ( my $i = 0; $i < $number_steps; $i++) {
			if ($length <= $edges[$i] && $length > $edges[$i+1]) {
				if (exists $bin{sprintf("%2d", $i+1)}) {
               		$bin{sprintf("%2d", $i+1)}++;
            	}
   	        	else {
       	        	$bin{sprintf("%2d", $i+1)} = 1;
   				}
			}
		}
#	}
}


foreach (sort (keys %bin)) {
	my $percent = $bin{$_}/$total_contigs * 100;
	my $sss = $edges[$_]+1;
	print OUTPUT "$sss\-$edges[$_-1]\t$bin{$_}\t",sprintf("%5.2f", $percent),"\n";
	$total_contigs1 += $bin{$_};
}

print OUTPUT "$total_contigs1\t$total_contigs\n";
