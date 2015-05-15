#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
my %opts;
GetOptions(\%opts,"i:s","p:s", "s:s", "n:s");
my $ver = "0.1";
my $usage=<<"USAGE";
        Program : $0
        Version : $ver
        Usage : $0 [options]
                -i              fastq read1 seq file; 
                -p              fastq read2 seq file;
                -n              new paired file name;
                -s              singl read file name;

USAGE
die $usage unless $opts{"i"} and ( $opts{"p"} and $opts{"n"} and $opts{"s"});
my $flag=0;

open (FQ,"$opts{i}")||die "Can't open file:$!\n";
open (FQ2, "$opts{p}") or die "Can't open file:$!\n";
open (OUT1, ">$opts{n}_read1.fastq") or die $!;
open (OUT2, ">$opts{n}_read2.fastq") or die $!;
open (SIG, ">$opts{s}") or die $!;

my $name;
my $seq;
my $qual;
my %all2;
my %all1;

while(<FQ2>){
    chomp;
    if(/^\@(.+)\/2/ and $flag == 0){
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
        if(/^\@(.+)\/1/ and $flag == 0){
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

foreach (keys %all1) {
	if (exists $all2{$_}) {
		print OUT1 $all1{$_};
		print OUT2 $all2{$_};
		delete $all2{$_};
	}
	else {
		print SIG $all1{$_};
	}
}

foreach (keys %all2) {
	print SIG $all2{$_};
}
