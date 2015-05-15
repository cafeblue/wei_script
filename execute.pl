#!/usr/bin/perl
# Jian Xu

$in = $ARGV[0];
open(IN, "< $in");
while (<IN>) {
  chomp($_);
  print "$_\n";
  system ($_);
}

