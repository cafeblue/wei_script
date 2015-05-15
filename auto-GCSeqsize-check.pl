#!/usr/bin/perl
# Jian Xu 

$home = "/home/gene/bioinfo/bin_xujian/";
$input = 'query.fna';
$cmd[0] = $home.'get_fasta_stats '.$input.' > query.gc';
$cmd[1] = 'cat query.gc | perl -nae \'{$_=~ s/\%//g; print $_;}\' > gcSeqsize.dat';
$cmd[2] = 'cp '.$home.'gcSeqsize.p .';
$cmd[3] = 'gnuplot gcSeqsize.p';
$cmd[4] = 'gv gcSeqsize.ps';
foreach $cmd (@cmd) {
  print "$cmd\n";
  system($cmd);
}
