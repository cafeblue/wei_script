#! /bin/env perl

use strict;
use List::Util qw(shuffle);
use Getopt::Long;
use PerlIO::gzip;

my $usage = << "USAGE";

    Program: $0
    Contact: Wei Wang (oneway.wang\@utoronto.ca)

    Usage: $0 [-p] -f file -n number
        -p    Use only on Paired End reads.
        -f    the reads file, (if -p used, *_R2.* will be the read2 file)
        -n    the number of the subset (if n>1, the number will be used as the final reads to be extracted
                                        if n<1, the number will be used as the portion to be extracted)

    Example: $0 -p -f 1_Index_sample_name_R1.fastq.gz -n 2000000
             $0 -f 1_Index.fastq -n 0.6

USAGE

my $sub_num ;
my $p;
my $file_read1;
my ($r1, $o1, $r2, $o2);

GetOptions ("n=s" => \$sub_num,    # numeric
            "f=s"   => \$file_read1,      # string
            "p"  => \$p);
die $usage unless ($sub_num && $file_read1);

my $lines = 0;
my $path = "";
if ($file_read1 =~ /\.gz$/) {
    #$lines = `zcat $file_read1 |wc -l`;
    if ($file_read1 =~ /(.+\/)/) {
        $path = $1;
    }
    my $name_tmp = $file_read1;
    $name_tmp =~ s/_clean.+//;
    $name_tmp =~ s/.+\///;
    $lines = `grep "$name_tmp" $path/reads_stat_old.txt |awk '{print \$2}'`;
    chomp($lines);
    # $lines /= 4;
    open $r1, "<:gzip", $file_read1 or die $!;
    my $out_read1 =  $file_read1;
    $out_read1 =~ s/.+\///;
    $out_read1 = "sb_" . $out_read1;
    open $o1, ">:gzip", $out_read1 or die $!;
    if ($p) {
        my $file_read2 = $file_read1;
        $file_read2 =~ s/_R1/_R2/;
        open $r2, "<:gzip", $file_read2 or die $!;
        my $out_read2 =  $file_read2;
        $out_read2 =~ s/.+\///;
        $out_read2 = "sb_" . $out_read2;
        open $o2, ">:gzip", $out_read2 or die $!;
    }
}
else {
    $lines = `wc -l $file_read1`;
    $lines /= 4;
    open $r1, $file_read1 or die $!;
    my $out_read1 = "sb_" . $file_read1 . ".gz";
    open $o1, ">:gzip", $out_read1 or die $!;
    if ($p) {
        my $file_read2 = $file_read1;
        $file_read2 =~ s/_R1/_R2/;
        open $r2, $file_read2 or die $!;
        my $out_read2 = "sb_" . $file_read2 . ".gz";
        open $o2, ">:gzip", $out_read2 or die $!;
    }
}

my @ids = (1..$lines);
if ($sub_num < 1) {
    $sub_num = int($lines * $sub_num);
    print "$sub_num reads were extracted.\n";
}

if ($lines == $sub_num) {
    die "You selected all of the reads($lines), nothing need to be done.\n";
}
elsif ($lines < $sub_num) {
    die "The reads number you entered ($sub_num) is larger than the total reads ($lines), please try again.\n"
}

@ids = shuffle(@ids);
@ids = @ids[0..$sub_num-1];
@ids = sort {$a <=> $b} @ids;

if ($p) {
    pe_output($r1, $r2, $o1, $o2, \@ids);
}
else {
    se_output($r1, $o1, \@ids);
}

sub pe_output{
    my $read1 = shift;
    my $read2 = shift;
    my $outp1 = shift;
    my $outp2 = shift;
    my $ids = shift;
    my $pointer = 1;
    while (1) {
        last unless ($#$ids != -1);
        my $now_id = shift(@{$ids});
        if ($pointer == $now_id) {
            my $lines1 = <$read1>;
            $lines1 .= <$read1>;
            $lines1 .= <$read1>;
            $lines1 .= <$read1>;
            my $lines2 = <$read2>;
            $lines2 .= <$read2>;
            $lines2 .= <$read2>;
            $lines2 .= <$read2>;
            print $outp1 $lines1;
            print $outp2 $lines2;
            $pointer++;
        }
        elsif ($pointer < $now_id) {
            my $lines1;
            my $lines2;
            for (0..$now_id-$pointer){
                $lines1 = <$read1>;
                $lines1 .= <$read1>;
                $lines1 .= <$read1>;
                $lines1 .= <$read1>;
                $lines2 = <$read2>;
                $lines2 .= <$read2>;
                $lines2 .= <$read2>;
                $lines2 .= <$read2>;
                $pointer++;
            }
            print $outp1 $lines1;
            print $outp2 $lines2;
        }
        else {
            die "WTF, Impossible happened???? pointer: $pointer and now_id: $now_id\n";
        }
    }
}

sub se_output{
    my $read1 = shift;
    my $outp1 = shift;
    my $ids = shift;
    my $pointer = 1;
    while (1) {
        last unless ($#$ids != -1);
        my $now_id = shift(@{$ids});
        if ($pointer == $now_id) {
            my $lines1 = <$read1>;
            $lines1 .= <$read1>;
            $lines1 .= <$read1>;
            $lines1 .= <$read1>;
            print $outp1 $lines1;
            $pointer++;
        }
        elsif ($pointer < $now_id) {
            my $lines1;
            for (0..$now_id-$pointer){
                $lines1 = <$read1>;
                $lines1 .= <$read1>;
                $lines1 .= <$read1>;
                $lines1 .= <$read1>;
                $pointer++;
            }
            print $outp1 $lines1;
        }
        else {
            die "WTF, Impossible happened???? pointer: $pointer and now_id: $now_id\n";
        }
    }
}
