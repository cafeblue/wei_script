#! /usr/bin/perl -w

use strict;

my $now_dir = `pwd`;
chomp($now_dir);
my $source_dir = $now_dir;
$source_dir =~ s/.+\///;
#print $source_dir,"\n";
$source_dir =  `ls -d /share/data1/Hisdata/Runs/$source_dir`;
chomp($source_dir);
#print $now_dir,"\t",$source_dir,"\n";
system ("rsync -ltr $source_dir/Data/reports .");
system ("rsync -ltr $source_dir/Data/reports .");

my @number = `ls -d $source_dir/Unaligned*`;
if ($#number == 0) {
    system("rsync -lrt $source_dir/Unaligned/Basecall_Stats_* .");
	system("rsync -ltr $source_dir/Unaligned/reads_stat.txt .");
	system("rsync -lrt $source_dir/Unaligned/Project_*/Sample_*/*_fastqc .");
	system("rsync -lrt $source_dir/Unaligned/Project_*/Sample_*/*_clean.fastq.gz .");
	system("rsync -lrt $source_dir/Unaligned/Project_*/Sample_*/*.zip .");
    system("touch finished.txt");
}
elsif ($#number > 0) {
	die "More than one Demultiplexing directory exists!!\n";
}
else {
	print "No Demultiplexing run... \n";
}
