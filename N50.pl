#!/bin/env perl

use strict;

my $inFile = $ARGV[0];  # size has to be sorted
my $i = $ARGV[1]; # the column that is the contig size; starting from 1;
$i--;
my @lines = ();
my $sum = 0;

open (IN, "< $inFile");
while (<IN>) {
  chomp;
  my @t = split(/[\s\t]/, $_);
  $sum += $t[$i];
  push(@lines, $t[$i]);
}
close (IN);

print "Total size $sum\n";
my $szSum = 0;
foreach (@lines) {
  $szSum += $_;
  my $percent = $szSum/$sum;
  if ($percent >= 0.5) {
    print "$_\t$percent\n";
    last;
  }
}
