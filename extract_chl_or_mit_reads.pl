#! /usr/bin/perl -w
# this script used to extract the reads list from the blantn result

# somt important thing:
#	1. you should specify the direcotry where the blastn file located.
#	2. your blastn blast file must be named as *mit*.blastn or *chl*.blastn. 
#	3. the output file will be named as reads_mit.lst or reads_chl.list.
#	

use strict;
use warnings;
use Bio::SearchIO;

if (! $ARGV[0]){
	print "You should specify the directory where the blastn files located!\n";
	print "\n\tUsage: $0 directory\t\n";
	exit; 
}

opendir (NOWD, "$ARGV[0]") || die $!;
my @blastf = grep(/\.blastn$/, readdir NOWD);
closedir (NOWD);

foreach (@blastf) {
	my $flag = 0;
	if (/mit/) {
		$flag = 1;
		open (RESMIT, ">reads_mit.list") || die $!;
	}
	elsif (/chl/) {
		$flag = 2;
		open (RESCHL, ">reads_chl.list") || die $!; 
	}
	else {
		print "Something Wrong?\n";
	}
	my $in = Bio::SearchIO->new(-format=>'blast', -file=>"$_");
	while (my $result = $in->next_result) {
#	my $query_length = $result->query_length();
#	my $query_name = $result->query_name();
		my $hit = $result->next_hit;
	    while ($hit = $result->next_hit) {
			if ($flag == 1){
				print   RESMIT $result->query_name(),"\t",$hit->name(),"\n";
			}
			elsif ($flag == 2){
				print   RESCHL $result->query_name(),"\t",$hit->name(),"\n";
			}
			else {
				print "Something Wrong? Maybe fault blastn result name...\n";
			}
		}
	}
}
