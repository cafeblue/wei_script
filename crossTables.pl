#!/usr/bin/perl
# Jian Xu

#print "./crossTable.pl refTable queryTable\n";

open (IN1, "< $ARGV[0]");
open (IN2, "< $ARGV[1]");
while (<IN1>) {
  chomp($_);
  @t = split(/[\t\s]/, $_);
  $key = $t[0];

#BEGIN following lines added by Wei Wang
	$key = (split(/\|/, $key))[3];
	$hash =$_;
	$hash =~ s/^\>\S+//;
	$hash{$key} = $hash;
#END

#  $key =~ s/\>//g;
#  $hash{$key} = $t[1];
}
close(IN1);
while (<IN2>) {
  chomp($_);
  @t = split(/[\t\s]/, $_);
#  $key = $t[0];
	$key = $t[1];
  $key =~ s/\>//g;
#  print "$key\t$hash{$key}\n";
#  print "$hash{$key}\t$key\n";
   print "$_\t$hash{$key}\n";
}
close(IN2);

