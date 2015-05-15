#! /usr/bin/perl -w

# used to add a length to the id.
# writen by Wei Wang Mar. 18 2010.

use strict;

if (@ARGV < 2) {
	print "\n\tUsage: $0 in_fasta out_fasta";
	print "\n\tExample: $0 allContigs.fasta allContigs1.fasta\n\n";
	exit(0);
}

open (INF, "$ARGV[0]") or die $!;
open (OUF, ">$ARGV[1]") or die $!;

my $id = "";
my $seq = "";
my $seq_tmp = "";
while (<INF>) {
	if (/^>/) {
		chomp;
		$seq_tmp = $seq;
		$seq_tmp =~ s/\n//g;
		print OUF $id,'_length_',length($seq_tmp),"\n";
		print OUF $seq;
		$seq = "";
		$id = (split(/\s/,$_))[0];
	}
	else {
		$seq .= $_;
	}
}


$seq_tmp = $seq;
$seq_tmp =~ s/\n//g;

print OUF $id,'_length_',length($seq_tmp),"\n";
print OUF $seq;
system ("sed -i '1d' $ARGV[1]");
