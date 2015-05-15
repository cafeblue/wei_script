#! /bin/env perl

use strict;
use PerlIO::gzip;


if ( $ARGV[1] eq "" || $ARGV[0] eq "" || $ARGV[2] eq "" ){
    die "\n    Usage: $0 input.fastq.gz reads_number output_prefix\n\n";
}

open GZ, "<:gzip", "$ARGV[0]" or die $!;
my $file_number = 0;
my $split_num = $ARGV[1] * 4;
while (<GZ>) {
    if ($. % $split_num == 1) {
        close OUFILE;
        my $ouf_name = $ARGV[2] . "_" . sprintf('%03d', $file_number) . ".fastq.gz";
        open OUFILE, "| gzip > $ouf_name" or die $!;
        $file_number++;
    }
    print OUFILE $_;
}
close(OUFILE);

