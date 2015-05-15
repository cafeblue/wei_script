#!/usr/bin/perl
# to get the best score one HSP, the input file the HSPs have to be sorted from high to low
# Jian Xu
#
while (<>) {
  chomp($_);
  $line = $_;
  @t = split(/\t/, $_);
  $read = $t[0];
  print "$_\n" unless exists($hash{$read});
  $hash{$read} = 1;
}

exit; 



