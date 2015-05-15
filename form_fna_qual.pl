#! /usr/bin/perl -w

# this script used to form new *.fna and *.qual files of which 
# you want to extract from a large fna and qual file.

# input file should be the list of reads accession
# another imput file shuld be the name of the fna and qual file
# for example, you have two files abc.fna and abc.qual, your input
# should be abc

use strict;

if ($ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "") {
	print "Wrong parametres!\n";
	print "\n\tUsage: $0 listfile input_file_name output_file_name\n";
	print "For example: $0 mit.list 1.TCA.454Reads mit\n";
	exit(0);
}

my $list = $ARGV[0];
my $name = $ARGV[1];
my $new_file_name = $ARGV[2];
my @reads_list;
my %fna;
my %qual;
my $key;
my %list;

my $fna_file = $name."\.fna";
my $qual_file = $name."\.qual";
open (FNA, "$fna_file") || die $!;
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

open (QUAL, "$qual_file") || die $!;
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

open (LIST, "$list") || die $!;
while (<LIST>) {	
	chomp;
	s/\s+$//;
	$list{$_} = $_;
#	my @tmp = split(/\t/, $_);
#	$list{$tmp[0]} = $tmp[1];
}
close(LIST);

open (NEWFNS, ">$new_file_name\.fna") || die $!;
open (NEWQUAL, ">$new_file_name\.qual") || die $!;
foreach (keys %list) {
	if (not exists $fna{$_}) {
		print "$_ not exist!\n";
		next;
	}
    print NEWFNS $fna{$_};                                                                             
    print NEWQUAL $qual{$_};                                                                           
}
