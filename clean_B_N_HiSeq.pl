#! /bin/env perl

use warnings;
use strict;
use threads;
use Getopt::Long;
use PerlIO::gzip;
$|++;
my %opts;
GetOptions(\%opts,"b:s","p:s", "n:s", "t:s", "f:s");
my $ver = "0.3";
my $usage=<<"USAGE";

        Program : $0
        Contact : Wei Wang(oneway.wang\@utoronto.ca)

        Usage : $0 -p [T/F] -f ["files"] [-b num] [-n num] [-t num]
                -p [T/F]        Paired End or not, required;
                -f [files]      files of read1, \e[1m\e[31mread1 files ONLY\e[0m, required;
                -b [number]     Cut off of percent of "#" in the quality, default 50; 
                -n [number]     Cut off of percent of "N" in the sequnce, default 10;
                -t [number]     threads number, default 8;

        Example1: $0 -p F -f "*.fastq"
        Example2: $0 -p T -f "*_R1.fastq.gz" -b 10 -n 10 -t 8
                             \e[5m\e[1m\e[31m"\e[0m is very important, Don't forget it!!!


USAGE
die $usage unless $opts{"p"} and $opts{f};

my @dirs = `ls $opts{f}`;
my $dir_number = $#dirs + 1;
print "There $dir_number files to be clean... \n";

my $paired_end = "F";
my $b = 50;
my $n = 10;
my $thread_number = 8;
chomp($dirs[0]);
my $reads_length;
if ($dirs[0] =~ m/\.gz$/) {
    $reads_length = length(`zcat $dirs[0] |head -2 | tail -1`) - 1;
}
else {
    $reads_length = length(`head -2 $dirs[0] | tail -1`) - 1;
}
if ($reads_length < 50) {
	$b = 10;
}

if ($opts{p}) {
	$paired_end = $opts{p};
}

if ($opts{b}) {
	$b = $opts{b};
}

if ($opts{n}) {
	$n = $opts{n};
}

if ($opts{t}) {
	$thread_number = $opts{t};
}

$b = int($reads_length * $b / 100);
$n = int($reads_length * $n / 100);

print "\"Ns\"      <=   $n\n";
print "\"#s\"      <=   $b\n";
print "Reads Length:   $reads_length\n";

open (REPORT, ">>./reads_stat_old.txt") or die $!;
print REPORT "filename\tclean_clusters\traw_clusters\tClean_Ratio\tTotal_Bases\tQ30\tQ20\n";
#print REPORT "Total_Cycles:\t$opts{c}\n";
print REPORT "Read_length:\t$reads_length\n";
my @thread;

my $thread_count = 0;
foreach (0..$#dirs) {
    chomp($dirs[$_]);
    $thread[$thread_count] = threads->create("clean_reads", "$paired_end", "$dirs[$_]");
    $thread_count++;
    if ($thread_count % $thread_number == 0) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
        $thread_count = 0;
    }
    elsif ($_ == $#dirs) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
    }
}

sub clean_reads {
	my $paired_end = $_[0];
	my $files = $_[1];
	my $clean_reads = 0;
	my $flag = 0;
    my $q20 = 0;
    my $q30 = 0;
    my $raw_clusters = 0;
	if ($paired_end eq "F" || $paired_end eq "f") {
		my $seq = "";
		my $outfile = $files;
        if ($files =~ /\.fastq\.gz$/) {
            open RD1, "<:gzip", "$files" or die $!;
		    $outfile =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fastq$/) {
            open RD1, "$files" or die $!;
		    $outfile =~ s/\.fastq$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fq\.gz$/) {
            open RD1, "<:gzip", "$files" or die $!;
		    $outfile =~ s/\.fq\.gz$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fq$/) {
            open RD1, "$files" or die $!;
		    $outfile =~ s/\.fq$/_clean\.fastq\.gz/;
        }
        else {
            die "file type is unknown! \n";
        }
		open OUF, ">:gzip", "$outfile" or die $!;
		open (OUF, ">$outfile") or die $!;
		while (my $lines = <RD1>) {
			if ($lines =~ /^\@.+\s\d+\:N\:/) {
                $raw_clusters++;
				$seq = $lines;
                $lines = <RD1>;
				$seq .= $lines;
				$lines =~ s/(A|T|G|C)//gi;
				if (length($lines) - 1 > $n) {
                    $lines = <RD1>; $lines = <RD1>;
					next;
				}
                $lines = <RD1>; $lines = <RD1>;
				$seq .= "+\n";
				$seq .= $lines;
				my $long_l = length($lines);
				$lines =~ s/\#//g;
				my $short_l = length($lines);
				if ($long_l - $short_l <= $b) {
					print OUF $seq;
					$clean_reads++;
                    my @ascii_character_numbers = unpack("C*", "$lines");
                    pop(@ascii_character_numbers);
                    while(my $q = pop(@ascii_character_numbers)) {
                        $q -= 33;
                        if ($q>=30) {
                            $q30++;
                            $q20++;
                        }
                        elsif ($q>=20) {
                            $q20++;
                        }
                    }
				}
			}
            else {
                $raw_clusters++;
                $lines = <RD1>; $lines = <RD1>; $lines = <RD1>;
            }
		}
		my $base = $clean_reads * $reads_length ;
        my $clean_ratio = sprintf('%6.3f', $clean_reads/$raw_clusters*100); 
		print REPORT "$files\t$clean_reads\t$raw_clusters\t$clean_ratio\t$base\t$q30\t$q20\n";
        close(OUF);
	}
	
	elsif ($paired_end eq "T" || $paired_end eq "t") {
		my $seq1;
		my $seq2;
        my $file2 = $files;
        $file2 =~ s/_R1/_R2/;
		my $outfile1 = $files;
		my $outfile2 = $file2;
        if ($files =~ /\.fastq\.gz$/) {
            open RD1, "<:gzip", "$files" or die $!;
            open RD2, "<:gzip", "$file2" or die $!;
		    $outfile1 =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
		    $outfile2 =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fastq$/) {
            open RD1, "$files" or die $!;
            open RD2, "$file2" or die $!;
		    $outfile1 =~ s/\.fastq$/_clean\.fastq\.gz/;
		    $outfile2 =~ s/\.fastq$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fq\.gz$/) {
            open RD1, "<:gzip", "$files" or die $!;
            open RD2, "<:gzip", "$file2" or die $!;
		    $outfile1 =~ s/\.fq\.gz$/_clean\.fastq\.gz/;
		    $outfile2 =~ s/\.fq\.gz$/_clean\.fastq\.gz/;
        }
        elsif ($files =~ /\.fq$/) {
            open RD1, "$files" or die $!;
            open RD2, "$file2" or die $!;
		    $outfile1 =~ s/\.fq$/_clean\.fastq\.gz/;
		    $outfile2 =~ s/\.fq$/_clean\.fastq\.gz/;
        }
        else {
            die "file type is unknown\n";
        }
		open OUF1, ">:gzip", "$outfile1" or die $!;
		open OUF2, ">:gzip", "$outfile2" or die $!;
		while (1) {
			my $file1line = <RD1>;
			my $file2line = <RD2>;
			last unless $file1line;
			if ( $file1line =~ /^\@.+\s\d+\:N\:/) {
                $raw_clusters++;
				$seq1 = $file1line;
				$seq2 = $file2line;
                $file1line = <RD1>; $file2line = <RD2>;
				$seq1 .= $file1line;
				$seq2 .= $file2line;
				$file1line =~ s/(A|T|G|C)//gi;
				$file2line =~ s/(A|T|G|C)//gi;
				if (length($file1line) - 1 > $n && length($file2line) - 1 > $n) {
                    $file1line = <RD1> ; $file1line = <RD1>;
                    $file2line = <RD2> ; $file2line = <RD2>;
                    next;
				}
                $file1line = <RD1> ; $file1line = <RD1>;
                $file2line = <RD2> ; $file2line = <RD2>;
				$seq1 .= "+\n";
				$seq2 .= "+\n";
				$seq1 .= $file1line;
				$seq2 .= $file2line;
				$file1line =~ s/\#//g;
				$file2line =~ s/\#//g;
				my $short1 = length($file1line);
				my $short2 = length($file2line);
				if ($reads_length - $short1 < $b && $reads_length - $short2 < $b) {
                    my @ascii_character_numbers = unpack("C*", "$file1line");
                    pop(@ascii_character_numbers);
                    push (@ascii_character_numbers, unpack("C*", "$file2line"));
                    pop(@ascii_character_numbers);
                    while(my $q = pop(@ascii_character_numbers)) {
                        $q -= 33;
                        if ($q>=30) {
                            $q30++;
                            $q20++;
                        }
                        elsif ($q>=20) {
                            $q20++;
                        }
                    }
					print OUF1 $seq1;
					print OUF2 $seq2;
					$clean_reads++;
				}
			}
            else {
                $raw_clusters++;
                $file1line = <RD1> ; $file1line = <RD1>; $file1line = <RD1>;
                $file2line = <RD2> ; $file2line = <RD2>; $file2line = <RD2>;
            }
		}
		my $base = $clean_reads * $reads_length * 2;
        my $clean_ratio = sprintf('%6.3f', $clean_reads/$raw_clusters*100); 
		print REPORT "$files\t$clean_reads\t$raw_clusters\t$clean_ratio\t$base\t$q30\t$q20\n";
                close(OUF1);
                close(OUF2);
	}
	
	else {
		die "Parameter -p is wrong!\n";
	}
	
}
