#!/usr/bin/perl
# Sort lines according to a certain column as identified by columnID
# Jian Xu

$inFile = $ARGV[0];
$colID = $ARGV[1];

$i = 0;
open (IN, "< $inFile");

while (<IN>) {
  chomp($_);
  $line = $_;
  @t = split(/\t+/, $_);
  $key = $t[$colID];
  $id = $line."\t\t\t".$i;
  $hash{$id} = $key;
  $i++;
}
#foreach $key (sort { $hash{$b} cmp $hash{$a} } keys %hash) {
foreach $key (sort { $hash{$b} <=> $hash{$a} } keys %hash) {
  ($line, $i) = split(/\t\t\t/, $key); 
  print "$line\n";
}
