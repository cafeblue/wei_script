#!/usr/bin/perl
# AutoLearn by Jian Xu
# Aug 2006

$in = $ARGV[0];
$type = $ARGV[1];
if ($type  eq 'read') { $minSz = 120; $e = '1e-20'; }
elsif ($type eq 'contig') { $minSz = 150; $e = '1e-100';}
elsif ($type eq '16S') { $minSz = 150; $e = '1e-100';}
else { print "Example: scriptName in.txt type > commandLines.txt\n"; exit; }

if ($in ne 'in.txt') { print "Example: scriptName in.txt type > commandLines.txt\n"; exit; }

$query = 'query.fna';
$cmd = '/home/gene/bioinfo/bin_xujian/auto-GC-check.pl &';
print "$cmd\n";
$cmd = '/home/gene/bioinfo/bin_xujian/auto-GCSeqsize-check.pl &';
print "$cmd\n";
$cmd = 'getorf -sequence '.$query.' -out orfs.faa.orig -minsize '.$minSz;
print "$cmd\n";
$cmd = '/home/gene/bioinfo/bin_xujian/removeOverlappingORFsFromFasta.pl orfs.faa.orig > orfs.faa'; 
print "$cmd\n";
# to see whether it is too large
# if yes, split into smaller files, generates qscript files
# print out message
#$numOfOrfs = `/gscuser/jxu/bin/get_fasta_stats orfs.faa |wc|awk \'\{print \$1\}\'`;
chomp($numOfOrfs);
print "echo $numOfOrfs\n";
if ($numOfOrfs >1000) {
  $useCluster = 'Y';
  $cmd = "echo Please use split_bigFasta.pl orfs.faa 1000";
  system($cmd);
} else {
  $useCluster = 'N';
} 

open(IN, "< $in");
while (<IN>) {
  chomp($_);
  next if $_ =~ /^\#/;
  @t = split(/[\s\t]+/, $_);
  $tool = $t[0];
  $query = $t[1];
  $db = $t[2];
  $path = $t[3];
#  print "$_\n";

  if ($tool =~ /mega/) {
    $outFile = $query.'_'.$tool.'_'.$db.'_'.$e.'.out';
    $cmd ='megablast -d '.$path.'/'.$db.' -i '.$query.' -p 0.9 -e '.$e.' -D 3 >'.$outFile; 
    print "$cmd\n";
    $outOutFile = $outFile.'.bestHit';
    $cmd = 'cat '.$outFile.' |sort -k 1 | /home/gene/bioinfo/bin_xujian/sortHitsInBlock_1.pl | /home/gene/bioinfo/bin_xujian/getBestScoreOneHit.pl > '.$outOutFile;
    print "$cmd\n";
    $annotFile = $outOutFile.'.annot';
    if ($db eq 'nt') { $headerFile = '/home/gene/bioinfo/bio_databases/nt.header.index';
    } elsif ($db eq 'SSU') { $headerFile = '/home/gene/bioinfo/bio_databases/SSU.header.index';
    } else {
      print "Error in $headerFile\n:"
    }
    $cmd = '/home/gene/bioinfo/bin_xujian/crossTables.pl '.$headerFile.' '.$outOutFile.' | sort -k 12 -n -r > '.$annotFile;
    print "$cmd\n";
  } elsif (($tool =~ /blast/) && ($query ne 'orfs.faa') ) {
    $outFile = $query.'_'.$tool.'_'.$db.'_'.$e.'.out';
    $cmd = "blastall -p ".$tool." -d ".$path.'/'.$db." -i ".$query." -e ".$e." -a 2 > ".$outFile;
    print "$cmd\n";
    $firstKnown = $outFile.'.firstKnownHit';
    $cmd = '/home/gene/bioinfo/bin_xujian/blast2firstKnownHit.pl '.$outFile.' |grep -v hypothe > '.$firstKnown; 
    print "$cmd\n";
    $cmd = '/home/gene/bioinfo/bin_xujian/sortColumn.pl '.$firstKnown.' 5 > '.$firstKnown.'.sorted';
    print "$cmd\n";

  } elsif ($query eq 'orfs.faa')  {
    if ($useCluster eq 'N') {
      $outFile = $query.'_'.$tool.'_'.$db.'_'.$e.'.out';
      $cmd = "blastall -p ".$tool." -d ".$path.'/'.$db." -i ".$query." -e ".$e." -a 2 > ".$outFile;  
      print "$cmd\n";
    } else {
      open (FOF, "< fasta.fof") or die "couldn't open fasta.fof: $!\n";
      while (<FOF>) {
        chomp($_);
        $query = $_;
        $qscript = 'qscript.'.$query; 
        $currPath = `pwd`;
        chomp($currPath);
        $origQuery = $query;
        $query = $currPath.'/'.$query;
        $outFile = $currPath.'/'.$origQuery.'_'.$tool.'_'.$db.'_'.$e.'.out';
        open (OUT, "> $qscript");
        $cmd = "cd ".$currPath;
        print (OUT "$cmd\n");
        $cmd = "blastall -p ".$tool." -d ".$path.'/'.$db." -i ".$query." -e ".$e." -a 2 > ".$outFile;
        print (OUT "$cmd\n"); 
      }
      close(FOF);
      $cmd = '';
      print "echo Please run cluster version of orfs.faa.*\n";
    }
  } else {
    print "$tool unknown\n"; exit; 
  }
}

