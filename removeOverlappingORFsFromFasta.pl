#!/usr/bin/perl
# remove those orfs that are internally harbored by others.
# Jian Xu

use DBI;
use Bio::SimpleAlign;
use Bio::AlignIO;
use Bio::SeqIO;
use Bio::Seq;
#use BPlite;

$input = $ARGV[0];

my  $in = Bio::SeqIO->new ('-file'=> $input,
                                 '-format'=>'fasta');

while ( $seq = $in->next_seq() ) {
  $id = $seq->display_id();
  $desc = $seq->desc();
  $id =~ s/\,//g;
  $sequence = $seq->seq();

  # Hash of arrays
  if ($id =~ /(\S+)\_/) { $contig = $1; } else { print "error\n"; exit;} 
  if ($desc =~ /\[(\d+)\s\-\s(\d+)/) { $left = $1; $right = $2; } else { print "error\n"; exit;} 
  if ($desc =~ /REVERSE/) {
    $rstart = $right; $rend = $left;
    push (@{$rstart{$contig} }, $rstart); # reverse strand
    push (@{$rend{$contig} }, $rend);
  } else { 
    $start = $left; $end = $right; 
    push (@{$start{$contig} }, $start);
    push (@{$end{$contig} }, $end);
  }
  
  #print "$id\n$desc\t$left\t$right\n";
}

my  $in = Bio::SeqIO->new ('-file'=> $input,
                                 '-format'=>'fasta');
while ( $seq = $in->next_seq() ) {
  $id = $seq->display_id();
  $desc = $seq->desc();
  $id =~ s/\,//g;
  $sequence = $seq->seq();
  $sequence{$id} = $sequence;
  $desc{$id} = $desc;
  #print "$id\n$desc\n"; 
  if ($id =~ /(\S+)\_/) { $contig = $1; } else { print "error\n"; exit;}
  @starts = @{$start{$contig}};
  @ends = @{$end{$contig}};
  $len = scalar(@starts);
  @rstarts = @{$rstart{$contig}};
  @rends = @{$rend{$contig}};
  $rlen = scalar(@rstarts);
  #print "$len\t$rlen\n";

  if ($desc =~ /\[(\d+)\s\-\s(\d+)/) { $left = $1; $right = $2; } else { print "
error\n"; exit;}
  if ($desc =~ /REVERSE/) {
    $start = $right; $end = $left;
  } else {
    $start = $left; $end = $right;
  }

  $flag = 'OK';

  if ($desc =~ /REVERSE/) {
    for ($i=0; $i< $rlen; $i++) {
      if (($start > $rstarts[$i]) && ($end < $rends[$i])) {
        $flag = 'NOT';
        last;
      }
    }
  } else {
    for ($i=0; $i< $len; $i++) {
#print "compare $start with $starts[$i]; $end with $ends[$i]\n";
      if (($start > $starts[$i]) && ($end < $ends[$i])) {
        $flag = 'NOT';
#print "Found\n";
        last;
      } 
    }
  }

  if ($flag eq 'OK') {
    print ">$id $desc\n";
    print "$sequence\n";
  }
}
