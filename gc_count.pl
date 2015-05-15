#!/usr/bin/perl -w


# this program is used to count the gc content in the squences.
# wrote by liyan in July.17 2009 

use strict;

if ( @ARGV < 3 ) {
	print "\n\tUsage: $0 fastafile output_GC_content_file output_GC_distribution_file\n";
	print "\tExample: $0 1.TCA.454Reads.fna gcContent.xls gcDistribution.xls\n";
	exit(0);
}

my $key;
my %fna;
my $len;
my %content;
my %gcc;
my $seq_number = 0;
my $seq_count = 0;
my $gc;
my $zlen;
my $zcount;
my $eve;


open (FNA, "$ARGV[0]") || die $!;
open (GCC, ">$ARGV[1]") || die $!;
open (GCD, ">$ARGV[2]") || die $!;
open (GCP, ">$ARGV[3]") || die $!;

while (<FNA>)
 { 
   chomp;
   if (/^\>/)
   {
     $key = $_;
	 $seq_number++;
   }
   else
   {
    $fna{$key} .= "$_";
   }
    
 }
 close (FNA);


 foreach (keys %fna)
 {      my $count = 0;
     
 	$len = length($fna{$_});
 	$zlen += $len; 
 	while ($fna{$_} =~ m/g|c/ig)
 	{$count++;
 	}
 	$zcount += $count;
	if (exists $gcc{sprintf("%2.0f", $count / $len * 100)}) {
		$gcc{sprintf("%d", $count / $len * 100)} += 1;
	}
	else {
		$gcc{sprintf("%d", $count / $len * 100)} = 1;
	}
 	
	$content{$_} = sprintf("%5.2f", $count / $len * 100);
 }
# print "$zlen\n";
# print "$zcount\n";
 
 $eve = sprintf("%5.2f", $zcount / $zlen * 100);
 print GCC "Ave_GC:\t$eve\n";
 print GCC "ID\tGC_content\n";
 print GCD "Ave_GC:\t$eve\n";
 print GCD "GC_content\tSeq_number\tseq_percent\n";

foreach (keys %content) {
	print GCC "$_\t$content{$_}\n";
}

foreach (sort keys %gcc) {
	$seq_count += $gcc{$_};
	print GCD "$_\%\t$gcc{$_}\t",sprintf("%5.2f", $gcc{$_}/$seq_number * 100),"\n";
	print GCP "$_\%\=$gcc{$_}\n";
}
print GCD "SeqNumber:\t$seq_count\tgcSeqNumber:\t$seq_count\n";
