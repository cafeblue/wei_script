#! /usr/bin/perl -w

# the file name should not be the total file name,
# if you specify the file parameter as "Reads",
# this stript will open the Reads.fna as the Reads
# sequences file. and open the Reads.qual as the 
# quality file.

# the second parameter used to form new files 
#named as *.fna and *.qual

# the third parameter used to form the result file.
# you'd better named it as *.xls.

use strict;

if ($ARGV[0] eq "" || $ARGV[1] eq "" ) {
	print "\n\tUsage: $0 dir output_table_file\n";
	print "   For example: $0 plot20090725 plot.xls\n";
	exit(0);
}

my %fna;
my %qual;
my $key;
my %job_id;
my $job_num = 10;

open (RES, ">$ARGV[1]") || die $!;
print RES "percent\tNumberoflargeContigs\tNumberoflargeBasses\tavgContigSize\tN50ContigSize\tlargestContigSize\tNumberofallContigs\tNumberofallBasses\n";

#my $fna_file = $name."\.fna";
#my $qual_file = $name."\.qual";
for (my $i = 10; $i <= 100; $i += 10) {
	my $filepath = "./$ARGV[0]$i/assembly/454NewblerMetrics.txt";
	open (METR, "$filepath") || die $!;
	print RES "$i\t";
	my $flag = 0;
	while (<METR>) {
		if (/largeContigMetrics/) {
			$flag++;
		}
		elsif (/numberOfContigs.+\=\s(\d+)\;/ && $flag == 1) {
			print RES "$1\t";
		}
		elsif (/numberOfBases.+\=\s(\d+)\;/ && $flag == 1) {
			print RES "$1\t";
		}
		elsif (/avgContigSize.+\=\s(\d+)\;/ && $flag == 1) {
			print RES "$1\t";
		}
		elsif (/N50ContigSize.+\=\s(\d+)\;/ && $flag == 1) {                                                     
            print RES "$1\t";
		}
		elsif (/largestContigSize.+\=\s(\d+)\;/ && $flag == 1) {                                                             print RES "$1\t";           
        }
		elsif (/allContigMetrics/) {
			$flag++;
		}
		elsif (/numberOfContigs.+\=\s(\d+)\;/ && $flag == 2) {
			print RES "$1\t";
		}
		elsif (/numberOfBases.+\=\s(\d+)\;/ && $flag == 2) {
			print RES "$1\n";
		}
	}
}

