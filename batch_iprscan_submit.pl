#! /usr/bin/perl -w

# used to batch submit jobs to lsf.
use strict;

if (@ARGV<3) {
	print "\n\tUsage: $0 dir file_suffix out_format";
	print "\n\tExample: $0 . fasta xml\n";
	exit(0);
}

opendir (IND, "$ARGV[0]") or die $!;
my @files = grep(/$ARGV[1]$/, readdir IND);

foreach (@files) {
	my $prefix = $_;
	$prefix =~ s/\.$ARGV[1]$//;
	my $cmd = "bsub -q normal -n 8 -x -o $prefix\_iprscan.log -e $prefix\_iprscan.err /home/gene/heyong/iprscan/bin/iprscan -cli -format $ARGV[2] -goterms -iprlookup -i $ARGV[0]\/$_ -o $prefix\.iprscan";
	print $cmd,"\n";
	system($cmd);
}
