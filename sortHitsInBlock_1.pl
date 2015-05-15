#!/usr/bin/perl -w
# to sort lines in each block; each block is megablast output for one contig
# Jian Xu

@tmp = ();
$oldContig='';
while (<>) {
  next if ($_ =~ /^\#/);
#  chomp($_);
  $line = $_;
  @t = split(/\t/, $_);
#  print "Line $line\n";
  $contig = $t[0];
  if ($contig eq $oldContig) {
#    print "add $contig, old contig $oldContig\n";
    $contig{$contig} .= $line;
  } else {
    $oldContig = $contig;
    $contig{$contig} = $line;
  }
}
foreach $contig (keys %contig) {
    # this is the block:
    $block = $contig{$contig};
#    print "$contig{$contig}\n\n";
    chomp($block);
    @tmp = split(/\n/, $block);
    foreach $item (@tmp) {
#print "item $item\n";
      chomp($item);
      @tmp1 = split(/\t/, $item);
      if ($item eq '') {
      } else {
        $score{$item} = $tmp1[11];
      }
    }
    foreach $key (sort { $score{$b} <=> $score{$a} } keys %score) {
      print "$key\n";
    }
#    print "\n\n\n";
    %score = ();
}




