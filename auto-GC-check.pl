#!/usr/bin/perl
# Jian Xu 
use strict;
use warnings;

my $usage = <<"USAGE";
    Usage: $0 fasta_file
    Example: $0 contig.fa

USAGE

if (@ARGV < 0) {
    die $usage;
}

my $home = "/home/wangw/my_script/";
my $input = "$ARGV[0]";
my @cmd;

$cmd[0] = 'get_fasta_stats '.$input.' > query.gc';
$cmd[1] = 'binizeData.pl '.'query.gc 100 1 2 > gcBinized.dat';
$cmd[2] = 'cp '.$home.'gcBinized.p .';
$cmd[3] = 'gnuplot gcBinized.p';
$cmd[4] = 'gv gcBinized.ps';
foreach my $cmd (@cmd) {
  print "$cmd\n";
  system($cmd);
}
