#! /usr/bin/perl -w

# the file name should not be the total file name,
# if you specify the file parameter as "Reads",
# this stript will open the Reads.fna as the Reads
# sequences file. and open the Reads.qual as the 
# quality file.

# the second parameter used to form new files 
#named as *.fna and *.qual

# the third parameter used to form the result file.
# you'd better named it as *.xls.

use strict;

if ($ARGV[0] eq "" || $ARGV[1] eq "" ) {
	print "\n\tUsage: $0 file newfile \n";
	print "   For example: $0 Reads_file New_Reads_file \n";
	exit(0);
}

my %fna;
my %qual;
my $key;
my %job_id;
my $job_num = 10;

open (FNA, "$ARGV[0]\.fna") || die $!;
while (<FNA>) {
        if (/^\>/) {
                $key = (split(/\s/, $_))[0];
                $key =~ s/\>//;
                $fna{$key} = "$_";
        }
        else {
                $fna{$key} .= "$_";
        }
}
close (FNA);

open (QUAL, "$ARGV[0]\.qual") || die $!;
while (<QUAL>) {
    if (/^\>/) {
        $key = (split(/\s/, $_))[0];
        $key =~ s/\>//;
        $qual{$key} = "$_";
    }
    else {
        $qual{$key} .= "$_";
    }
}
close (QUAL);

open (P10, ">$ARGV[1]10\.fna") ||die $!;
open (Q10, ">$ARGV[1]10\.qual") ||die $!;
open (P20, ">$ARGV[1]20\.fna") ||die $!;
open (Q20, ">$ARGV[1]20\.qual") ||die $!;
open (P30, ">$ARGV[1]30\.fna") ||die $!;
open (Q30, ">$ARGV[1]30\.qual") ||die $!;
open (P40, ">$ARGV[1]40\.fna") ||die $!;
open (Q40, ">$ARGV[1]40\.qual") ||die $!;
open (P50, ">$ARGV[1]50\.fna") ||die $!;
open (Q50, ">$ARGV[1]50\.qual") ||die $!;
open (P60, ">$ARGV[1]60\.fna") ||die $!;
open (Q60, ">$ARGV[1]60\.qual") ||die $!;
open (P70, ">$ARGV[1]70\.fna") ||die $!;
open (Q70, ">$ARGV[1]70\.qual") ||die $!;
open (P80, ">$ARGV[1]80\.fna") ||die $!;
open (Q80, ">$ARGV[1]80\.qual") ||die $!;
open (P90, ">$ARGV[1]90\.fna") ||die $!;
open (Q90, ">$ARGV[1]90\.qual") ||die $!;
open (P95, ">$ARGV[1]100\.fna") ||die $!;
open (Q95, ">$ARGV[1]100\.qual") ||die $!;

foreach (keys %fna) {
	if (rand(100) <= 10) {
		print P10 $fna{$_};
		print Q10 $qual{$_};
	}
	if (rand(100) <= 20) {
		print P20 $fna{$_};
		print Q20 $qual{$_};
	}
	if (rand(100) <= 30) {
		print P30 $fna{$_};
		print Q30 $qual{$_};
	}
	if (rand(100) <= 40) {
		print P40 $fna{$_};
		print Q40 $qual{$_};
	}
	if (rand(100) <= 50) {
		print P50 $fna{$_};
		print Q50 $qual{$_};
	}
	if (rand(100) <= 60) {
		print P60 $fna{$_};
		print Q60 $qual{$_};
	}
	if (rand(100) <= 70) {
		print P70 $fna{$_};
		print Q70 $qual{$_};
	}
	if (rand(100) <= 80) {
		print P80 $fna{$_};
		print Q80 $qual{$_};
	}
	if (rand(100) <= 90) {
		print P90 $fna{$_};
		print Q90 $qual{$_};
	}
	if (rand(100) <= 95) {
		print P95 $fna{$_};
		print Q95 $qual{$_};
	}
}

close (P10);
close (Q10);
close (P20);
close (Q20);
close (P30);
close (Q30);
close (P40);
close (Q40);
close (P50);
close (Q50);
close (P60);
close (Q60);
close (P70);
close (Q70);
close (P80);
close (Q80);
close (P90);
close (Q90);
close (P95);
close (Q95);

