#! /usr/bin/perl -w

# the first parameter is the directory where all the 
# fasta file located.

use strict;

my $path = $ARGV[0];

opendir (DIR, "$path") || die $!;
my @fastafiles = grep(/\.fasta$/, readdir DIR);
closedir (DIR);
my $c=0;

foreach (@fastafiles) {
	$c++;
	my $in = $path.$_;
	my $out = $_;
	$out =~ s/fasta$/mpiblastn/;
	my $cmd = "bsub -q long -n 27 -o job$c.log -e job$c.err mpiexec -n 27 /home/gene/bioinfo/mpiblast/bin/mpiblast -p blastn -d nt -e 1 -i $_  -o $out";
	system ($cmd);
}
