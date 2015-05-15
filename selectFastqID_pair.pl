#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use PerlIO::gzip;
use warnings;
use Getopt::Long;
my %opts;
GetOptions(\%opts,"i:s","fq1:s", "fq2:s", "o:s");
my $ver = "0.1";
my $usage=<<"USAGE";
        Program : $0
        Version : $ver
        Usage : $0 [options]
                -i              id list file; 
                -fq1            fastq read1 seq file;
                -fq2            fastq read2 seq file;
                -o              output file name;

USAGE
die $usage unless $opts{"i"} and ( $opts{"fq1"} and $opts{"fq2"} and $opts{"o"});
my $flag=0;

open (LIST,"$opts{i}")||die "Can't open file:$!\n";
if ($opts{fq1} =~ /\.gz/) {
    open FQ, "<:gzip", $opts{fq1} or die $!;
    open FQ2, "<:gzip", $opts{fq2} or die $!;
}
else {
    open (FQ, "$opts{fq1}") or die "Can't open file:$!\n";
    open (FQ2, "$opts{fq2}") or die "Can't open file:$!\n";
}
open (OUT1, ">$opts{o}_read1.fastq") or die $!;
open (OUT2, ">$opts{o}_read2.fastq") or die $!;

my $name;
my $seq;
my $qual;
my %all2;
my %all1;

while(<FQ2>){
    chomp;
    if(/^\@(.+)\s.*$/ and $flag == 0){
        $name = $1;
        $flag ++;
    }elsif($flag == 1){
        $seq = $_;
        $flag ++;
    }elsif(/^\+/ and $flag == 2){
        $flag ++;
    }elsif($flag == 3){
        $qual = $_;
        $flag = 0;
		my $each1="\@$name\/2\n$seq\n\+\n$qual\n";
		$all2{$name} = $each1;
    }
}
close FQ2;

$flag = 0;
while(<FQ>){
        chomp;
        if(/^\@(.+)\s.*$/ and $flag == 0){
                $name = $1;
                $flag ++;
        }elsif($flag == 1){
                $seq = $_;
                $flag ++;
        }elsif(/^\+/ and $flag == 2){
                $flag ++;
        }elsif($flag == 3){
                $qual = $_;
                $flag = 0;
				my $each="\@$name\/1\n$seq\n\+\n$qual\n";
				$all1{$name} = $each;
        }

}
close FQ;

while (<LIST>) {
	chomp;
#	if ( $.%2 == 1) {
#		s/\/.{1}$//;
#		print OUT1 $all1{$_};
#	}
#	elsif ($.%2 == 0) {
#		s/\/.{1}$//;
#		print OUT2  $all2{$_};
#	}
#	else {
#		die "Something wrong?!\n";
#	}
    print OUT1 $all1{$_};
    print OUT2 $all2{$_};
}
