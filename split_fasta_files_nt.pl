#! /usr/bin/perl -w

# the first parameter is the .fna file to be splitted.
# the second parameter is the sequence number.

if ($ARGV[0] eq "" || $ARGV[1] eq "") {
	print "\n\t Usage: $0 file number\n";
	print "\t Example: $0 . 3000\n";
	exit(0);
}

use strict;
use warnings;

my $new_fasta_filename;

open (NOWFILE, "$ARGV[0]") || die $!;
my $species = $ARGV[0];
my $file_type = $ARGV[0];
$species =~ s/\..+?$//;
$file_type =~ s/.+\./\./;
my $counter = 0;
while (<NOWFILE>) {
#	if (/^\>.+length\=(\d+)/ && $flag >= 1) {
	if (/^\>/) {
#		if ( $1 <= 50) {
#			$flag = 2;
#			next;
#		}
		if ($counter % $ARGV[1] == 0) {
			$new_fasta_filename = "$species"."$counter"."$file_type";
			open (FILE, ">$new_fasta_filename") or die $!;
		}
		print FILE $_;
		$counter++;
	}
#	elsif (/^\w+$/ && $flag <= 1) {
	else {
		print FILE $_;
	}
}


