#! /usr/bin/perl -w

# this script is used to form a .qual file for the response .fasta file

use strict;

if (@ARGV < 2) {
	die "\n\tUsage: $0 input.fasta quality\n\tExample: $0 454.fna 64";
}

my $quality = $ARGV[1];

open (INF, "$ARGV[0]") || die $!;
if ($ARGV[0] =~ /\.fna$|\.fasta$/) {
	my $newname = $ARGV[0];
	$newname =~ s/fna$|fasta$/qual/;
	open (OUTP, ">$newname") || die $!;
}
else {
	my $newname = $ARGV[0]."\.qual";
	open (OUTP, ">$newname") || die $!;
}

while (<INF>) {
	if (/^>/) {
		print OUTP $_;
	}
	elsif (/^$/) {
		next;
	}
	else {
		s/(A|T|G|C)/$quality /ig;
		s/N/20 /ig;
		s/\s$//;
		print OUTP $_;
#		print OUTP "$quality " x length($_);
#		print OUTP "\n";
	}
}
