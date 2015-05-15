#! /bin/env perl 

use warnings;
use strict;
use Getopt::Long;
use PerlIO::gzip;
use PerlIO::via::Bzip2;
use threads;
$|++;
my %opts;
GetOptions(\%opts,"b:s","p:s", "t:s", "n:s", "c:s");
my $ver = "0.2";
my $usage=<<"USAGE";
        Program : $0
        Version : $ver
        Contact : Wei Wang(oneway.wang\@utoronto.ca)
        Usage : $0 [options]
                -p [T/F]        Paired End or not, if not parameter -2 will be ignored, default F;
                -b [number]     Cut off of percent of "#" in the quality, default 50; 
                -n [number]     Cut off of percent of "N" in the sequnce, default 10;
                -t [number]     thread number, default 8;
                -c [number]     cycle number, default 8;

        Example1: $0 -p F 
        Example2: $0 -p T -b 10 -n 10 
USAGE
die $usage unless $opts{"p"};

my $paired_end = $opts{p};
my $reads_length;
my @files;
my $thread_number = 8;
if ($paired_end eq "F" || $paired_end eq "f") {
    @files = `find . -name "*_R1*"`;
    chomp($files[0]);
    $reads_length = length(`tail -1 $files[0]`) - 1;
}

elsif ($paired_end eq "T" || $paired_end eq "t") {
    @files = `find . -name "*_R1*"`;
    chomp($files[0]);
    $reads_length = length(`tail -1 $files[0]`) - 1;
}

else {
    die "Parameter -p is wrong!\n";
}

my $b = 50;
my $n = 10;
if ($reads_length < 50) {
    $b = 10;
}

if ($opts{t}) {
    $thread_number = $opts{t};
}

if ($opts{b}) {
    $b = $opts{b};
}


if ($opts{n}) {
    $n = $opts{n};
}

my $reads = 0;
my $clean_reads = 0;
my $flag = 0;
$b = int($reads_length * $b / 100);
$n = int($reads_length * $n / 100);

print "\"Ns\"      <=   $n\n";
print "\"#s\"      <=   $b\n";
print "Reads Length:   $reads_length\n";

open (REPORT, ">>reads_stat.txt") or die $!;
print REPORT "filename\tclean_clusters\tTotal_Bases\tClean_Ratio\tQ30\tQ20\tPF_clusters\traw_cluster\tGC\n";
print REPORT "Cycles_Number:\t$opts{c}\n";
print REPORT "Read_length:\t$reads_length\n";

my @thread;

my $thread_count = 0;
foreach (0..$#files) {
    chomp($files[$_]);
    $thread[$thread_count] = threads->create("clean_reads", "$paired_end", "$files[$_]");
    $thread_count++;
    if ($thread_count % $thread_number == 0) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
        $thread_count = 0;
    }
    elsif ($_ == $#files) {
        foreach (0..$thread_count-1) {
            $thread[$_]->join();
        }
    }
}


sub clean_reads {
    my $paired_end = $_[0];
    my $files = $_[1];
    my $clean_reads = 0;
    my $reads = 0;
    my $flag = 0;
    my $q20 = 0;
    my $q30 = 0;
    if ($paired_end eq "F" || $paired_end eq "f") {
        my $seq = "";
        if ($files =~ /\.gz$/) {
            open RD1, ":gzip", "$files" or die $!;
        }
        elsif ($files =~ /\.bz2$/) {
            open (RD1, "<:via(Bzip2)", "$files") or die $!;
        }
        else {
            open (RD1, "$files") or die $!;
        }
        my $outfile = $files;
        $outfile =~ s/_R1.+/_R1_clean.fastq.gz/;
        open OUF, ">:gzip","$outfile" or die $!;
        while (<RD1>) {
            if (/^\@HW/ && $flag == 0) {
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
                s/B//g;
                my $short_l = length($_);
                if ($long_l - $short_l <= $b) {
                    print OUF $seq;
                    $clean_reads++;
                    my @ascii_character_numbers = unpack("C*", "$_");
                    pop(@ascii_character_numbers);
                    while(my $q = pop(@ascii_character_numbers)) {
                        $q -= 64;
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
        $file =~ s/\/GERALD_\d{2}\-\d{2}\-\d{4}_solexa\//\//;
        my $base = $clean_reads * $reads_length ;
        print REPORT "$file\t$clean_reads\t$base\t", sprintf('%.3f', $clean_reads/$reads*100);
        print REPORT "%\t",sprintf('%6.3f', $q30/$base*100),"%\t";
        print REPORT sprintf('%6.3f', $q20/$base*100),"%\t";
        print REPORT $reads,"\tunknown\n";
        close(OUF);
    }
    elsif ($paired_end eq "T" || $paired_end eq "t") {
        my $seq1;
        my $seq2;
        my $files2 = $files;
        $files2 =~ s/_R1/_R2/;
#        open (RD1, "$files") or die $!;
        if ($files =~ /\.gz$/) {
            open RD1, ":gzip", "$files" or die $!;
            open RD2, ":gzip", "$files2" or die $!;
        }
        elsif ($files =~ /\.bz2$/) {
            open (RD1, "<:via(Bzip2)", "$files") or die $!;
            open (RD2, "<:via(Bzip2)", "$files2") or die $!;
        }
        else {
            open (RD1, "$files") or die $!;
            open (RD2, "$files2") or die $!;
        }
        my $outfile1 = $files;
        my $outfile2 = $files2;
        $outfile1 =~ s/_R1.+/_R1_clean.fastq.gz/;
        $outfile2 =~ s/_R2.+/_R2_clean.fastq.gz/;
        open OUF1, ">:gzip", "$outfile1" or die $!;
        open OUF2, ">:gzip", "$outfile2" or die $!;
        while (1) {
            my $file1line = <RD1>;
            my $file2line = <RD2>;
            last unless $file1line;
            if ( $file1line =~ /^\@FC81EK/ && $flag == 0) {
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
                $file1line =~ s/B//g;
                $file2line =~ s/B//g;
                my $short1 = length($file1line);
                my $short2 = length($file2line);
                if ($reads_length - $short1 <= $b && $reads_length - $short2 <= $b) {
                    print OUF1 $seq1;
                    print OUF2 $seq2;
                    $clean_reads++;
                    my @ascii_character_numbers = unpack("C*", "$file1line");
                    pop(@ascii_character_numbers);
                    push (@ascii_character_numbers, unpack("C*", "$file2line"));
                    pop(@ascii_character_numbers);
                    while(my $q = pop(@ascii_character_numbers)) {
                        $q -= 64;
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
        $file =~ s/\/GERALD_\d{2}\-\d{2}\-\d{4}_solexa\//\//;
        my $base = $clean_reads * $reads_length * 2;
        print REPORT "$file\t$clean_reads\t$base\t", sprintf('%6.3f', $clean_reads/$reads*100);
        print REPORT "%\t",sprintf('%6.3f', $q30/$base*100),"%\t";
        print REPORT sprintf('%6.3f', $q20/$base*100),"%\t";
        print REPORT $reads,"\tunknown\n";
        close(OUF1);
        close(OUF2);
    }

    else {
        die "Parameter -p is wrong!\n";
    }
}
