#! /usr/bin/perl -w
# this script used to batch submit megablast.
# Read following item to make this scipt work smoothly.

#	1. you should specify the directory where the fasta located.
#		right after the command.
#	2. the name of the files sould be named as *.fasta.
#	3. the output file will be named as *.megablastn

use strict;

opendir (DIR, ".") || die $!;
my @fastafiles = grep(/\.fasta$/, readdir DIR);
closedir (DIR);

foreach (@fastafiles) {
	my $out = $_;
	$out =~ s/\.fasta/\.megablastn/;
	my $cmd = "bsub -q serial -o job.log -e job.err megablast -d /home/gene/bioinfo/bio_databases/nt -o "."$out"."  -i "."$_"." -p 0.9 -D 3 -e 1e-100";
	system ($cmd);
}
