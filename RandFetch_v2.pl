#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
#Data:2010-08-20;
my %opts;
GetOptions(\%opts,"i:s","p:s", "s:s", "n:s");
my $ver = "1.1";
my $usage=<<"USAGE";
        Program : $0
        Version : $ver
        Contact : Wang Wei
        Usage : $0 [options]
                -i              fastq seq file; 
                -p              Percent of  total reads number;
                -n              concret reads number;
                -s              read2 fastq seq file

	\e[31;1m WARNING!!!! Don't set -p and -n parameters simultaneously !!\e[01;0m

USAGE
die $usage unless $opts{"i"} and ( $opts{"p"} || $opts{"n"});
my %hash=();
my $fq=$opts{i};
my $rds_name=$fq;
$rds_name=~s/(.*)\..*$/$1/;

my $total=`grep -c "^@" $fq`;
chomp($total);
#print "$total\n";
my $want;
if ($opts{p}) {
	$want=$total*$opts{p}/100;
}
elsif ($opts{n}) {
	$want=$opts{n};
}
else {
	die "Something Wrong? -n or -p not set?\n";
}
#my $n;
#$/="\@";
my @all1=();
my @all2=();
my ($name,$seq,$qual);
my $flag=0;
open (FQ,"$opts{i}")||die "Can't open file:$!\n";

if ($opts{s}) {
	open (FQ2, "$opts{s}") or die "Can't open file:$!\n";
	while(<FQ2>){
	    chomp;
	#	@x=();
	    if(/^\@(.+)/ and $flag == 0){
	        $name = $1;
	        $flag ++;
	#		$n++;
	    }elsif($flag == 1){
	        $seq = $_;
	        $flag ++;
	    }elsif(/^\+/ and $flag == 2){
	        $flag ++;
	    }elsif($flag == 3){
	        $qual = $_;
	        $flag = 0;
			my $each="\@$name\n$seq\n\+\n$qual\n";
			push @all2,"$each";
	    }
	}
	close FQ2;
}

while(<FQ>){
        chomp;
#		@x=();
        if(/^\@(.+)/ and $flag == 0){
                $name = $1;
                $flag ++;
#				$n++;
        }elsif($flag == 1){
                $seq = $_;
                $flag ++;
        }elsif(/^\+/ and $flag == 2){
                $flag ++;
        }elsif($flag == 3){
                $qual = $_;
                $flag = 0;
				my $each="\@$name\n$seq\n\+\n$qual\n";
				push @all1,"$each";
        }

}

close FQ;
my %Rand;
open (OUT1,">$rds_name\_read1\_per.fq")||die "$!\n";

if ($opts{s}) { 
	open (OUT2,">$rds_name\_read2\_per.fq")||die "$!\n";
	srand(rand($total));
	my $ni1=0;
	while (1) {
#		my $rand = int(rand($total))+1;
		my $rand = int(rand($total));
		if (!exists $Rand{$all1[$rand]}) {
			$Rand{$all1[$rand]}=1;
			$ni1++;
			print OUT1 "$all1[$rand]";
			print OUT2 "$all2[$rand]";
		}
		if ($ni1 >= $want) {
			last;
		}
	}
	exit (0);
}

srand(rand($total));
my $n=0;
while (1) {
#	my $rand = int(rand($total))+1;
	my $rand = int(rand($total));
	if (!exists $Rand{$all1[$rand]}) {
		$Rand{$all1[$rand]}=1;
		$n++;
		print OUT1 "$all1[$rand]";
	}
	if ($n >= $want) {
		last;
	}
}
close OUT1;
