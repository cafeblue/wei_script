#! /usr/bin/perl -w

use strict;

my $now_dir = `pwd`;
chomp($now_dir);
my $source_dir = $now_dir;
$source_dir =~ s/.+\///;
#print $source_dir,"\n";
$source_dir =  `ls -d /share/data1/GAdata/Runs/$source_dir`;
chomp($source_dir);
#print $now_dir,"\t",$source_dir,"\n";
system ("rsync -ltr $source_dir/Data/reports .");
my $flag = 0;

my @number = `ls -d $source_dir/Data/C*Firecrest1.8.0_*solexa/Bustard1.8.0_*_solexa/Demu*`;

if ($#number == 0) {
	system ("rsync -ltr $source_dir/Data/C*Firecrest1.8.0_*solexa/Bustard1.8.0_*_solexa/Demu*/SamplesDirectories.csv .");
	system ("rsync -ltr $source_dir/Data/C*Firecrest1.8.0_*solexa/Bustard1.8.0_*_solexa/Demu*/reads_stat.txt .");
	my @samp_dirs = `ls -d $source_dir/Data/C*Firecrest1.8.0_*solexa/Bustard1.8.0_*_solexa/Demu*/0??`;
	foreach (@samp_dirs) {
		chomp;
		my $target_dir = $_;
		$target_dir =~ s/.+\///;
		system("mkdir $target_dir");
		system("rsync -lrt $_/GE*/*sequence_clean.txt.gz $target_dir");
		system("rsync -lrt $_/GE*/*.zip $target_dir");
		system("rsync -lrt $_/GE*/*_fastqc $target_dir");
		system("rsync -lrt $_/GE*/Summary.htm $target_dir");
	}
	$flag++;
}
elsif ($#number > 0) {
	die "More than one Goat directory exists!!\n";
}
else {
	print "No goat run... \n";
}

print $flag,"\n";

@number = `ls $source_dir/Data/Inte*/Base*/Demu*/SamplesDirectories.csv`;
if ($#number == 0) {
	if ($flag > 0) {
        system ("cat $source_dir/Data/Inte*/Base*/Demu*/SamplesDirectories.csv >> SamplesDirectories.csv");
	    system ("cat $source_dir/Data/Inte*/Base*/Demu*/reads_stat.txt >> reads_stat.txt");
	}
	else {
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/Demu*/SamplesDirectories.csv .");
	    system ("rsync -ltr $source_dir/Data/Inte*/Base*/Demu*/reads_stat.txt .");
	}
	my @samp_dirs = `ls -d $source_dir/Data/Inte*/Base*/Demu*/0??`;
	foreach (@samp_dirs) {
		chomp;
		my $target_dir = $_;
		$target_dir =~ s/.+\///;
		system("mkdir $target_dir");
		system("rsync -lrt $_/GE*/*sequence_clean.txt.gz $target_dir");
		system("rsync -lrt $_/GE*/*.zip $target_dir");
		system("rsync -lrt $_/GE*/*_fastqc $target_dir");
		system("rsync -lrt $_/GE*/Summary.htm $target_dir");
	}
    system("touch finished.txt");
	$flag++;
}
elsif ($#number > 0) {
	die "More than one Demultiplexing directory exists!!\n";
}
else {
	print "No Demultiplexing run... \n";
}

print $flag,"\n";

@number = `ls $source_dir/Data/Inte*/Base*/GERALD_*solexa/reads_stat.txt`;
if ($#number == 0) {
	if ($flag > 0) {
		system ("cat $source_dir/Data/Inte*/Base*/GERALD_*solexa/reads_stat.txt >> reads_stat.txt");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*sequence_clean.txt.gz .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*.zip .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*_fastqc .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/Summary.htm .");
	}
	else {
		system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/reads_stat.txt .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*sequence_clean.txt.gz .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*.zip .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/*_fastqc .");
        system ("rsync -ltr $source_dir/Data/Inte*/Base*/GERALD_*solexa/Summary.htm .");
	}
}
elsif ($#number > 0) {
	die "More than one Gerald directory exists!\n";
}
else {
	print "No Gerald run...\n";
}
