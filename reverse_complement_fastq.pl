#! /share/data/software/ActivePerl-5.12/bin/perl
##! /usr/bin/perl 

use strict;
use PerlIO::gzip;
use threads;

my $usage = <<"USAGE";
        Program : $0                                                                                                                                           
        Contact : Wang Wei                                                                                                                                     
        Usage : $0 [files...]
        Example1: $0 file.fq file2.fq.gz file3.fq file4.fq.gz file5.fastq

USAGE



if (@ARGV < 1) {
    die $usage;
}

my @thread;
my $thread_count = 0;
foreach (0..$#ARGV) {
    $thread[$_] = threads->create("rev_com", "$ARGV[$_]");
}

foreach (0..$#ARGV) {
    $thread[$_]->join();
}

sub rev_com {
    my $file = $_[0];
    my $file_out = $file;
    my ($FILEA, $FILEB);
    if ($file =~ /\.gz$/) {
        open $FILEA, "<:gzip", "$file" or die $!;
        $file_out =~ s/\.(.+?)\.gz/_revcom\.$1\.gz/;
        open $FILEB, ">:gzip", "$file_out" or die $!;
    }
    else {
        open $FILEA, "$file" or die $!;
        $file_out =~ s/\.(.+?)/_revcom\.$1/;
        open $FILEB, ">$file_out" or die $!;
    }
    while (<$FILEA>) {
        if ($.%4 == 1) {
            print $FILEB $_;
        }
        elsif ($.%4 == 2) {
            chomp;
            tr/ATGC/TACG/;
            my $tmp = reverse($_);
            print $FILEB $tmp,"\n";
        }
        elsif ($.%4 == 3) {
            print $FILEB "+\n";
        }
        elsif ($.%4 == 0) {
            chomp;
            my $tmp = reverse($_);
            print $FILEB $tmp,"\n";
        } 
    }
}
