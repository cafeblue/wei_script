#! /usr/bin/perl -w

#used to split a fq file or paired fq file into random two parts.

use strict;

if (@ARGV < 1 ) {
	print "\n\tUsage: $0 file1 [file2 file3 ...]  \n";
	print "\tFor example: $0 reads1.fastq reads2.fastq \n";
	exit(0);
}

foreach (@ARGV) {
	my $flag = 2;
	my $nowfile = $_;
	my $outfile1 = $nowfile;
	my $outfile2 = $nowfile;
	$outfile1 =~ s/\./\_1\./;
	$outfile2 =~ s/\./\_2\./;
	open (INF, "$nowfile") or die $!;
	open (OUF, ">$outfile1") or die $!;
	open (OUG, ">$outfile2") or die $!;
	while (<INF>) {
		if (/^\@HWI-EAS/ && $flag == 2) {
			$flag = 1;
			print OUF $_;
		}
		elsif (/^\@HWI-EAS/ && $flag == 1) {
			$flag = 2;
			print OUG $_;
		}
		elsif ($flag == 1) {
			print OUF $_;
		}
		elsif ($flag == 2) {
			print OUG $_;
		}
		else {
			print "something wrong?\n";
			exit(0);
		}
	}
	close(INF);
	close(OUF);
	close(OUG);
}
