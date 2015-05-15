#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use PerlIO::gzip;
use warnings;

if(@ARGV != 5){
        print "Usage: perl <min_length> <in_fq1> <in_fq2> <out_fq_1> <out_fq_2>\n";
        exit;
}
my ($min_length,$in_fq1,$in_fq2,$out_fq1,$out_fq2) = @ARGV;
my $flag = 0;
open FQ1,">$out_fq1"  or die "OpenEror: $out_fq1, $!\n";
open IN, "<:gzip", $in_fq1  or die "OpenError: $in_fq1, $!\n";
my ($name,$seq,$qual,$subqual);
while(<IN>){
        chomp;
        if(/^\@(.+)/ and $flag == 0){
                $name = $1;
				$name =~ s/\/1//g;
                $flag ++;
        }elsif($flag == 1){
                $seq = $_;
                $flag ++;
        }elsif(/^\+/ and $flag == 2){
                $flag ++;
	}elsif($flag == 3){
		$qual = $_;
		$qual =~ s/#+$//;
		if(length($qual) > $min_length){
			$seq = substr($seq,0,length($qual));
			print FQ1 "\@$name\/1\n$seq\n\+\n$qual\n";
		}
		else{
			$seq = substr($seq,0,$min_length);
			$qual=substr($_,0,$min_length);
			print FQ1 "\@$name\/1\n$seq\n\+\n$qual\n";
		}
		$flag = 0;
	}
}
close IN;
close FQ1;

#open(FQ0,">$out_fq\_single.fq") or die "OpenEror: $out_fq\_single.fq, $!\n";

open FQ2,">$out_fq2"  or die "OpenEror: $out_fq2, $!\n";
open IN, "<:gzip", $in_fq2 or die "OpenError: $in_fq2, $!\n";
while(<IN>){
	chomp;
	if(/^\@(.+)/ and $flag == 0){
			$name = $1;
			$name =~ s/\/2//g;
			$flag ++;
	}elsif($flag == 1){
			$seq = $_;
			$flag ++;
	}elsif(/^\+/ and $flag == 2){
			$flag ++;
	}elsif($flag == 3){
			$qual = $_;
		$qual =~ s/#+$//;
		$flag = 0;
		if(length($qual) > $min_length){
			$seq=substr($seq,0,length($qual));
			print FQ2 "\@$name\/2\n$seq\n\+\n$qual\n";
		}else{
			$seq=substr($seq,0,$min_length);
			$qual=substr($_,0,$min_length);
			print FQ2 "\@$name\/2\n$seq\n\+\n$qual\n";
		}
	}
}
close IN;
close FQ2;
