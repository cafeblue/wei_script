#!/usr/bin/perl

while (<>) {
  chomp($_);
  $hash{$_}++; 
  $total++;
}

foreach $key (sort { $hash{$b} <=> $hash{$a} } keys %hash) {
  print "$key\t$hash{$key}\t$hash{$key}/$total\n";
}
