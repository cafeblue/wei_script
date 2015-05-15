#! /usr/bin/perl -w

# four parameters:
# first (file): the name of file which lines in these file need to be selected.
# second (file): the name of file contains item list want to be selected in first file.
# thrid (integer): which column are the items in second file located in the first file.
# forth (file): output file name.

use strict;

if (@ARGV < 4) {
	print "\n\tUsage: $0 inputfile list_file number outputfile";
	print "\n\tExample: $0 nanno2nr.xls list 1 my_selection\n";
	print "\n\t\%\%\%\%\%\%\%\%\%\%\%\%\%   \e[31;1m WARNING!!!! \e[01;0m  \%\%\%\%\%\%\%\%\%\%\%\%\%";
	print "\n\tthe first file should \e[31;1m NOT \e[01;0m be be larger \e[31;1m 1G \e[01;0m , other wise the memory will be exhausted!\n\n";
	exit(0);
}

open (INF, "$ARGV[0]") or die $!;
my %infile;
my $column = $ARGV[2] - 1;

while (<INF>) {
	my $id = (split(/\t/, $_))[$column];
	$infile{$id} = $_;
}

open (LST, "$ARGV[1]") or die $!;
open (OUF, ">$ARGV[3]") or die $!;
while (<LST>) {
	chomp;
	if (not exists $infile{$_}) {
		print "item $_ in line $. does not exist in file $ARGV[0]!!!\n";
	}
	else {
		print OUF $infile{$_};
	}
}
