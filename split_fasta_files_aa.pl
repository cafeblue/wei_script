#! /usr/bin/perl -w

# the first parameter is the .fna file to be splitted.
# the second parameter is the sequence number.

if ($ARGV[0] eq "" || $ARGV[1] eq "") {
	print "\n\t Usage: $0 file number prefix\n";
	print "\t Example: $0 in.fasta 3000 out_\n";
	exit(0);
}

use strict;
use warnings;

my $new_fasta_filename;

open (NOWFILE, "$ARGV[0]") || die $!;
my $file_type = $ARGV[0];
$file_type =~ s/.+\./\./;
my $flag = 1;
my $counter = 0;
while (<NOWFILE>) {
	if (/^\>/ && $flag >= 1) {
		if ($counter % $ARGV[1] == 0) {
			$new_fasta_filename = "$ARGV[2]"."$counter"."$file_type";
			open (FILE, ">$new_fasta_filename") or die $!;
		}
		$flag = 0;
		print FILE $_;
		$counter++;
	}
#	elsif (/^\w+$/ && $flag <= 1) {
	elsif ($flag <= 1) {
		$flag = 1;
		print FILE $_;
	}
}


