#!/usr/bin/perl
# Jian Xu

$in = $ARGV[0];
$max = $ARGV[1];
$interval = $ARGV[2];
$columnID = $ARGV[3];  # which column in the input file to use

open(IN, "< $in");
while (<IN>) {
  chomp($_);
  @t = split(/[\s\t]/, $_);
  $value = $t[$columnID];
#  print "$_ $columnID $value\n";
  $binValue = $value/$interval;
  $binID = $binValue; $binID =~ s/\.\d+//g;
#  print "$binValue $binID\n";
  $hash{$binID}++;
}
for ($i=0; $i< ($max/$interval +1); $i++) {
  $low[$i] = $i * $interval;
  $high[$i] = $low[$i] + $interval;
  # add 03/23/2007
  if (exists($hash{$i})) {} else { $hash{$i}=0; }
  print "$low[$i] $high[$i] $hash{$i}\n";

}


