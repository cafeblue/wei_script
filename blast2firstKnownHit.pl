#!/usr/bin/env perl
# Jian Xu

use Bio::SimpleAlign;
use Bio::SearchIO;
use Bio::SeqIO;
use Bio::Seq;

$FilePath = $ARGV[0];

$s = "\t";     # spacer
$ID=0;
$sbjctName = $gb = '';
$length = $sbjctLength = $score = 0;
open (IN, "< $FilePath");

my $report_blast= new Bio::SearchIO(  -format => 'blast',
                                       -file   => $FilePath
                                       );

while(my $blast = $report_blast->next_result) {
  $name ='';
  $flag = 'empty';
  $contig = '';
  $query = $blast->query_name;
  @tmp = split(' ', $query); $name = $tmp[0];
  @tmp = split('_', $name); $contig = $tmp[0];
  $length = $blast->query_length;
#  print "INPUTREAD $name \n";
  while (my $sbjct = $blast->next_hit) {
    $sbjctName =       $sbjct->name;
    $sbjctDesc =       $sbjct->description;
    $sbjctName = $sbjctName.' '.$sbjctDesc;

    $sbjctLength =     $sbjct->length;
   #  print "$sbjctName $sbjctLength\n";
    while (my $hsp = $sbjct->next_hsp) {
      $score = $hsp->score;
      $bits =        $hsp->bits;
      $percent =     $hsp->percent_identity; $percent=sprintf("%.1f", $percent);
      $E =           $hsp->evalue();
      $match =       $hsp->matches;
      $sbjctlength =      $hsp->length;
      $queryBegin =  $hsp->start('query');
      $queryEnd =    $hsp->end('query');
      $sbjctBegin =  $hsp->start('sbjct');
      $sbjctEnd =    $hsp->end('sbjct');
      last;
    }
    #print "Hi $name $sbjctName $P\n";

    #if ($P <= 0.001) {
    if ($E <= 1e-6) {
 #     print "Looking at $name\t$sbjctName\t$percent\t$E\t$score ...\n";
      if (($sbjctName =~ /uncult/)  || ($sbjctName =~ /uniden/) || ($sbjctName =~ / bacterium/)) { 
        #print "Oops, $sbjctName\n"; 
        next; }
      #print "$name\t$sbjctName\t$P\n";
      #print "$queryEnd, $queryBegin, $length, $sbjctEnd, $sbjctBegin\n";
      print "$name$s$length$s$sbjctName$s$percent$s$E$s$score$s$queryBegin$s$queryEnd$s$sbjctBegin$s$sbjctEnd\n";
      $flag = 'hit';
    } else {
      #exit; print "$name$s$length$shypothetical protein\n"; #exit;
    }
  $ID++;
  last; # only get the last hit
  }
  if ($flag eq 'empty') {  $desc = 'hypothetical protein'; print "$name\t$desc\n"; }
 
}
