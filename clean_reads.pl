#! /bin/env perl

use strict;
use PerlIO::gzip;
use threads;

my $usage = << USAGE;

    Program: $0
    Contact: Wei Wang(oneway.wang\@utoronto.ca)

    Usage: $0 -d dir -p [T/F] [-b num] [-n num] [-t num] [-6/-3]
            -d directory where raw data located.
            -p Paired-End?
            -b percentage of the low quality bases [default 50%].
            -n percentage of the "N" bases [default 10%].
            -t threads number [default 8].
            -6 phrap64?
            -3 phrap33 [default]?

    Example: 

        $0 -d rawdata -p F
        $0 -d rawdata_dir -p T -b 20 -n 5 -t 2 -3

USAGE

my $thread_count = 8;
my $low_q = 50;
my $unkno = 10;
