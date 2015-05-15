#! /usr/bin/perl -w


# this program is used to extract the abnormal reads from
# .fna and .qual file. 
# the first parameter should be the name of .fna and 
# .qual file
# the second parameter is the new file name of most reads
# the third parameter is the new file name of the filtered 
# reads



use strict;

sub filter {
	my $tmp = $_[0];
	if ($tmp =~ m/x\=(\S+)\s/) {
		$tmp = $1;
	}
	else {
		print "Something wrong? errcode: 001\n";
	}
	my @tmp = sort(split(/\s/, $_[1]));
	my $num = @tmp;
	my $flag = 0;
	for (my $i = 0; $i < $num-1; $i++) {
		if ($tmp[$i+1] - $tmp[$i] > 5) {
			$flag++;
			if ($tmp >= $tmp[$i]) {
				return ("1");
			}
			else {
				return ("0");
			}
		}
	}
	if ($flag == 0) {
		if ($tmp >= $tmp[0]) {
			return("1");
		}
		else {
			print "Something wrong? errcode:002\n";
		}
	}
}

if ($ARGV[0] eq "") {
	print "\n\tUsage: $0 infile outfile filteredfile\n";
	print "\tExample: $0 1.TCA.454Reads 1.TCA.454Reads_new 1.TCA.454Reads_filtered\n";
	exit(0);
}

my %fna;
my %qual;
my $key;
my %squal;
my %filtered;
my %unfiltered;
my %yaxle;

open (NFNA, ">$ARGV[2].fna") || die $!;
open (NQUAL, ">$ARGV[2].qual") || die $!;
open (NFFNA, ">$ARGV[1].fna") || die $!;
open (NFQUAL, ">$ARGV[1].qual") || die $!;

open (FNA, "$ARGV[0]\.fna") || die $!;
while (<FNA>) {
        if (/^\>/) {
			$key = $_;
            $fna{$_} = "$_";
        }
        else {  
            $fna{$key} .= "$_";
        }
}
close (FNA);

open (QUAL, "$ARGV[0]\.qual") || die $!;
while (<QUAL>) {
    if (/^\>/) {
		$key = $_;
        $qual{$_} = "$_";
    }
    else {
        $qual{$key} .= "$_";
    }
}
close (QUAL);

foreach (keys %fna) {
	if (/x=(\S+).+y=(\S+)/) {
		if ($1 >= 1857 && $2 >= 1612 && $2 <= 2310) {
			$squal{$_} = "$2";
			$yaxle{$2} .= "$1 ";
		}
	}
}

foreach (keys %squal) {
	if (filter($_, $yaxle{$squal{$_}}) == "1") {
		print NFNA $fna{$_};
		print NQUAL $qual{$_};
		delete $fna{$_};
		delete $qual{$_};
	}	
}

foreach (keys %fna) {
	print NFFNA $fna{$_};
	print NFQUAL $qual{$_};
}
