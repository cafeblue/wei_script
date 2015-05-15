#!/usr/bin/perl -w

use strict;
use DBI;

my $in = $ARGV[0];
my $nohit = $ARGV[1];
my $OUTgenera = $ARGV[2];
my $OUTsubkingdom = $ARGV[3];
my $OUTqc_properties = $ARGV[4];
die "Usage:	$0 \$InputFile_listBlastSingle \$InputFile_nohit \$countGenera \$countSubkingdom \$qcProperties\n" if(@ARGV != 5);

my $driver = "mysql";
my $database = "ncbi_taxonomy";
my $host = "124.16.151.190";
my $user = "cafeblue";
my $password = "bacdavid";
my $dbh = DBI -> connect("DBI:$driver:$database;$host", $user, $password, {'RaiseError' => 1}) or die $DBI::errstr;

my $high = 98;
my $low = 90;
my $thresholdRatio = 0.01;
my (%countGenera, %countSubkingdom, %countMitochondrion, %countChloroplast, %countNucleolus, %countSubkingdomH, %countSubkingdomM, %countSubkingdomL);

open INblast, "$in" or die $!;
open OUTgenera, ">$OUTgenera" or die $!;
open OUTsubkingdom, ">$OUTsubkingdom" or die $!;
open OUTQCprop, ">$OUTqc_properties" or die $!;

my $i = 0;
my $countBesthit = 0;
while (<INblast>){
	chomp;

	if (/(\d+)%\t(\S+)\t(\S+)\t(\S+)\t(\S+)$/){
		$countBesthit++;
		if ($1 >= $high){
			if (/^(\S+)\t(\S+)\t(\S+)\|(\S+)(\.)/){
				my $SQL_comm = "select taxtree.taxtree from taxtree inner join gi2taxid_nt on gi2taxid_nt.taxid = taxtree.taxid where gi2taxid_nt.accession = '$4'";
				my $sth = $dbh -> prepare($SQL_comm) or die $dbh -> errstr;
				$sth -> execute() or die $dbh -> errstr;
				while (my $ref = $sth -> fetchrow_hashref()){
					my $queryResult = $ref->{'taxtree'};
					if ($queryResult =~ /(\d+)#(\d+)#(\d+)#(\d+)#(\d+)/){
						$countGenera{$1}++;
						$countSubkingdom{$5}++;
						$countSubkingdomH{$5}++;
					}
					$i++;
					print "$i\n";
				}
				# some records that don't exist in database are not calculated!
			}
			if (/(mitochondrion)/){
				$countMitochondrion{"high"}++;
			}elsif(/chloroplast/){
				$countChloroplast{"high"}++;
			}else{
				$countNucleolus{"high"}++;
			}
		}elsif($1 < $low){
			if (/^(\S+)\t(\S+)\t(\S+)\|(\S+)(\.)/){
				my $SQL_comm = "select taxtree.taxtree from taxtree inner join gi2taxid_nt on gi2taxid_nt.taxid = taxtree.taxid where gi2taxid_nt.accession = '$4'";
				my $sth = $dbh -> prepare($SQL_comm) or die $dbh -> errstr;
				$sth -> execute() or die $dbh -> errstr;
				while (my $ref = $sth -> fetchrow_hashref()){
					my $queryResult = $ref->{'taxtree'};
					if ($queryResult =~ /(\d+)#(\d+)#(\d+)#(\d+)#(\d+)/){
						$countGenera{$1}++;
						$countSubkingdom{$5}++;
						$countSubkingdomL{$5}++;
					}
					$i++;
					print "$i\n";
				}
				# some records that don't exist in database are not calculated!
			}
			if (/(mitochondrion)/){
				$countMitochondrion{"low"}++;
			}elsif(/chloroplast/){
				$countChloroplast{"low"}++;
			}else{
				$countNucleolus{"low"}++;
			}
		}else{
			if (/^(\S+)\t(\S+)\t(\S+)\|(\S+)(\.)/){
				my $SQL_comm = "select taxtree.taxtree from taxtree inner join gi2taxid_nt on gi2taxid_nt.taxid = taxtree.taxid where gi2taxid_nt.accession = '$4'";
				my $sth = $dbh -> prepare($SQL_comm) or die $dbh -> errstr;
				$sth -> execute() or die $dbh -> errstr;
				while (my $ref = $sth -> fetchrow_hashref()){
					my $queryResult = $ref->{'taxtree'};
					if ($queryResult =~ /(\d+)#(\d+)#(\d+)#(\d+)#(\d+)/){
						$countGenera{$1}++;
						$countSubkingdom{$5}++;
						$countSubkingdomM{$5}++;
					}
					$i++;
					print "$i\n";
				}
				# some records that don't exist in database are not calculated!
			}
			if (/(mitochondrion)/){
				$countMitochondrion{"medium"}++;
			}elsif(/chloroplast/){
				$countChloroplast{"medium"}++;
			}else{
				$countNucleolus{"medium"}++;
			}
		}
	}
}

my $countNohit = 0;
open(INnohit, "< $nohit") or die $!;
$countNohit++ while <INnohit>;
print OUTQCprop "pievalue:$countNohit;$countBesthit\n";


print OUTQCprop "alabel:nucleolus;mitochondrion;chloroplast\n";
print OUTQCprop "alayer1:";
if (exists $countNucleolus{high}){
	print OUTQCprop "$countNucleolus{high};";
}else {
	print OUTQCprop "0;";
}
if (exists $countMitochondrion{high}){
	print OUTQCprop "$countMitochondrion{high};";
}else {
	print OUTQCprop "0;";
}
if (exists $countChloroplast{high}){
	print OUTQCprop "$countChloroplast{high}\n";
}else {
	print OUTQCprop "0\n";
}
print OUTQCprop "alayer2:";
if (exists $countNucleolus{medium}){
	print OUTQCprop "$countNucleolus{medium};";
}else {
	print OUTQCprop "0;";
}
if (exists $countMitochondrion{medium}){
	print OUTQCprop "$countMitochondrion{medium};";
}else {
	print OUTQCprop "0;";
}
if (exists $countChloroplast{medium}){
	print OUTQCprop "$countChloroplast{medium}\n";
}else {
	print OUTQCprop "0\n";
}
print OUTQCprop "alayer3:";
if (exists $countNucleolus{low}){
	print OUTQCprop "$countNucleolus{low};";
}else {
	print OUTQCprop "0;";
}
if (exists $countMitochondrion{low}){
	print OUTQCprop "$countMitochondrion{low};";
}else {
	print OUTQCprop "0;";
}
if (exists $countChloroplast{low}){
	print OUTQCprop "$countChloroplast{low}\n";
}else {
	print OUTQCprop "0\n";
}

foreach my $genera (sort {$countGenera{$b} <=> $countGenera{$a}} keys %countGenera){
	printf OUTgenera "%d\t%d\t%f\t", $genera, $countGenera{$genera}, $countGenera{$genera}/$i;
	my $SQL_comm = "select name from scientific_name where taxid = $genera";
	my $sth = $dbh -> prepare($SQL_comm) or die $dbh -> errstr;
	$sth -> execute() or die $dbh -> errstr;
	my $flag = 0;
	while (my $ref = $sth -> fetchrow_hashref()){
		my $queryResult = $ref->{'name'};
		print OUTgenera "$queryResult\n";
		$flag = 1;
	}
	if ($flag == 0){
		print OUTgenera "unkown\n";
	}
}

my @printSubkingdomID;
my @printSubkingdomNAME;
my $countSubkingdomID = 0;
foreach my $subkingdom (sort {$countSubkingdom{$b} <=> $countSubkingdom{$a}} keys %countSubkingdom){
	printf OUTsubkingdom "%d\t%d\t%f\t", $subkingdom, $countSubkingdom{$subkingdom}, $countSubkingdom{$subkingdom}/$i;
	my $SQL_comm = "select name from scientific_name where taxid = $subkingdom";
	my $sth = $dbh -> prepare($SQL_comm) or die $dbh -> errstr;
	$sth -> execute() or die $dbh -> errstr;
	my $flag = 0;
	my $queryResult;
	while (my $ref = $sth -> fetchrow_hashref()){
		$queryResult = $ref->{'name'};
		print OUTsubkingdom "$queryResult\n";
		$flag = 1;
	}
	if ($flag == 0){
		$queryResult = "unknown";
		print OUTsubkingdom "$queryResult\n";
	}
	if ($countSubkingdom{$subkingdom}/$i > $thresholdRatio){
		$printSubkingdomID[$countSubkingdomID] = $subkingdom;
		$printSubkingdomNAME[$countSubkingdomID] = $queryResult;
		$countSubkingdomID++;
	}
}

print OUTQCprop "blabel:";
for (my $i = 0;$i < $countSubkingdomID;$i++){
	if ($i+1 == $countSubkingdomID){
		print OUTQCprop "$printSubkingdomNAME[$i]\n";
	}else{
		print OUTQCprop "$printSubkingdomNAME[$i];";
	}
}

print OUTQCprop "blayer1:";
for(my $i = 0;$i < $countSubkingdomID;$i++){
	if (exists $countSubkingdomH{$printSubkingdomID[$i]}){
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "$countSubkingdomH{$printSubkingdomID[$i]}";
		}else{
			print OUTQCprop "$countSubkingdomH{$printSubkingdomID[$i]};";
		}
	}else{
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "0";
		}else{
			print OUTQCprop "0;";
		}
	}
}
print OUTQCprop "\n";

print OUTQCprop "blayer2:";
for(my $i = 0;$i < $countSubkingdomID;$i++){
	if (exists $countSubkingdomM{$printSubkingdomID[$i]}){
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "$countSubkingdomM{$printSubkingdomID[$i]}";
		}else{
			print OUTQCprop "$countSubkingdomM{$printSubkingdomID[$i]};";
		}
	}else{
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "0";
		}else{
			print OUTQCprop "0;";
		}
	}
}
print OUTQCprop "\n";

print OUTQCprop "blayer3:";
for(my $i = 0;$i < $countSubkingdomID;$i++){
	if (exists $countSubkingdomL{$printSubkingdomID[$i]}){
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "$countSubkingdomL{$printSubkingdomID[$i]}";
		}else{
			print OUTQCprop "$countSubkingdomL{$printSubkingdomID[$i]};";
		}
	}else{
		if ($i+1 == $countSubkingdomID){
			print OUTQCprop "0";
		}else{
			print OUTQCprop "0;";
		}
	}
}

$dbh->disconnect;
exit 0;