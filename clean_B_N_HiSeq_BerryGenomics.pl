#! /bin/env perl

use warnings;
use strict;
use threads;
use Getopt::Long;
use PerlIO::gzip;
$|++;
my %opts;
GetOptions(\%opts,"b:s","p:s", "1:s", "n:s", "2:s", "t:s", "r:s", "c:s");
my $ver = "0.3";
my $usage=<<"USAGE";

        Program : $0
        Contact : Wei Wang(oneway.wang\@utoronto.ca)

        Usage : $0 -p [T/F] [-b num] [-n num] [-t num]
                -p [T/F]        Paired End or not, if not parameter -2 will be ignored, default F;
                -b [number]     Cut off of percent of "#" in the quality, default 50; 
                -n [number]     Cut off of percent of "N" in the sequnce, default 10;
                -t [number]     threads number, default 8;
                -c [number]     cycle number, default 8;

        Example1: $0 -p F 
        Example2: $0 -p T -b 10 -n 10 -t 8

USAGE
die $usage unless $opts{"p"};

#my @dirs = `find . -name *_R1_0??.fastq.gz`;
my @dirs = `find . -name "*_R1.fastq.gz"`;
my $dir_number = $#dirs + 1;
print "There $dir_number dirs to be clean... \n";

my $paired_end = "F";
my $b = 50;
my $n = 10;
my $thread_number = 8;
chomp($dirs[0]);
my $reads_length = length(`zcat $dirs[0] |head -2 | tail -1`) - 1;
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
print REPORT "filename\tclean_clusters\tTotal_Bases\tClean_Ratio\tQ30\tQ20\tPF_clusters\traw_cluster\tGC\n";
print REPORT "Total_Cycles:\t$opts{c}\n";
print REPORT "Read_length:\t$reads_length\n";
my @thread;

my $thread_count = 0;
foreach (0..$#dirs) {
    chomp($dirs[$_]);
#    my $dir_tmp = chomp($dirs[$_]);
#    my @thread_count = threads->list();
#    my $thread_count = $#thread_count+1;
#    print $#thread_count,"\n";
    $thread[$thread_count] = threads->create("clean_reads", "$paired_end", "$dirs[$_]");
    $thread_count++;
    if ($thread_count % $thread_number == 0) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
        $thread_count = 0;
#        while ($#thread_count >= 0) {
#            sleep 60;
#            @thread_count = threads->list();
#	    print "=> ",$#thread_count,"\n";
#        }
    }
    elsif ($_ == $#dirs) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
    }
}

#foreach (0..$#dirs) {
#    print $_,"\n";
#    my @thread_count = threads->list();
#    print $#thread_count,"\n";
#    while ($#thread_count >= $thread_number-1) {
#        sleep 10;
#	print "judge right\n";
#    }
#    $thread[$_]->join();
#}

sub clean_reads {
	my $paired_end = $_[0];
	my $files = $_[1];
	my $clean_reads = 0;
	my $reads = 0;
	my $flag = 0;
        my $q20 = 0;
        my $q30 = 0;
        my $raw_clusters = 0;
	if ($paired_end eq "F" || $paired_end eq "f") {
		my $seq = "";
		open RD1, "<:gzip", "$files" or die $!;
		my $outfile = $files;
		$outfile =~ s/\.fastq\.gz$/_clean\.fastq/;
#		$outfile =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
#		open OUF, ">:gzip", "$outfile" or die $!;
		open (OUF, ">$outfile") or die $!;
		while (<RD1>) {
			if (/^\@HW.+\s\d+\:(\w)\:/ && $flag == 0) {
                                $raw_clusters++;
				if ($1 eq "Y") {
					next;
				}
				$reads++;
				$flag++;
				$seq = $_;
			}
			elsif ($flag == 1) {
				$flag++;
				$seq .= $_;
				s/(A|T|G|C)//gi;
				if (length($_) - 1 > $n) {
					$flag = 0;
					next;
				}
			}
			elsif ($flag == 2) {
				$seq .= "+\n";
				$flag++;
			}
			elsif ($flag == 3) {
				$seq .= $_;
				my $long_l = length($_);
				s/\#//g;
				my $short_l = length($_);
				if ($long_l - $short_l <= $b) {
					print OUF $seq;
					$clean_reads++;
                                        my @ascii_character_numbers = unpack("C*", "$_");
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
				$flag = 0;
			}
		}
		my $file = $files;
		my $base = $clean_reads * $reads_length ;
		print REPORT "$file\t$clean_reads\t$base\t$q30\t$q20\t$reads\t$raw_clusters\n";
                close(OUF);
	}
	
	elsif ($paired_end eq "T" || $paired_end eq "t") {
		my $seq1;
		my $seq2;
                my $file2 = $files;
#                $file2 =~ s/_R1_/_R2_/;
                $file2 =~ s/_R1/_R2/;
		open RD1, "<:gzip", "$files" or die $!;
		open RD2, "<:gzip", "$file2" or die $!;
		my $outfile1 = $files;
		my $outfile2 = $file2;
		$outfile1 =~ s/\.fastq\.gz$/_clean\.fastq/;
		$outfile2 =~ s/\.fastq\.gz$/_clean\.fastq/;
#		$outfile1 =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
#		$outfile2 =~ s/\.fastq\.gz$/_clean\.fastq\.gz/;
#		open OUF1, ">:gzip", "$outfile1" or die $!;
#		open OUF2, ">:gzip", "$outfile2" or die $!;
		open (OUF1, ">$outfile1") or die $!;
		open (OUF2, ">$outfile2") or die $!;
		while (1) {
			my $file1line = <RD1>;
			my $file2line = <RD2>;
			last unless $file1line;
			if ( $file1line =~ /^\@HW.+\s\d+\:(\w)\:/ && $flag == 0) {
                                $raw_clusters++;
				if ($1 eq "Y") {
					next;
				}
				$reads++;
				$flag++;
				$seq1 = $file1line;
				$seq2 = $file2line;
			}
			elsif ($flag == 1) {
				$flag++;
				$seq1 .= $file1line;
				$seq2 .= $file2line;
				$file1line =~ s/(A|T|G|C)//gi;
				$file2line =~ s/(A|T|G|C)//gi;
				if (length($file1line) - 1 > $n && length($file2line) - 1 > $n) {
					$flag = 0;
					next;
				}
			}
			elsif ($flag == 2) {
				$seq1 .= "+\n";
				$seq2 .= "+\n";
				$flag++;
			}
			elsif ($flag == 3) {
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
				$flag = 0;
			}
		}
		my $file = $files;
		my $base = $clean_reads * $reads_length * 2;
		print REPORT "$file\t$clean_reads\t$base\t$q30\t$q20\t$reads\t$raw_clusters\n";
                close(OUF1);
                close(OUF2);
	}
	
	else {
		die "Parameter -p is wrong!\n";
	}
	
}
