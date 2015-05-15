#! /usr/bin/perl -w

use strict;

opendir (DIR, ".") || die $!;
my @fastafiles = grep(/\.fasta$/, readdir DIR);
closedir (DIR);

foreach (@fastafiles) {
	my $out = $_;
	$out =~ s/fasta/blastn1/;
	my $cmd = "bsub -q serial -o job.log -e job.err megablast -d /home/gene/bioinfo/bio_databases/nt -o "."$out"."  -i "."$_"." -p 0.9 -D 3 -e 1e-100";
	system ($cmd);
}
