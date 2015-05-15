#! /usr/bin/perl -w

# writen by Wei Wang, Dec. 11 2010

use strict;
use Net::FTP;
use DBI();


my $ftp = Net::FTP->new("ftp.genome.jp", Debug => 0)
  or die "Cannot connect to ftp://ftp.genome.jp: $@";
$ftp->login("anonymous",'-anonymous@')
  or die "Cannot login ", $ftp->message;
$ftp->cwd("/pub/kegg/pathway")
  or die "Cannot change working directory ", $ftp->message;
my @species_dir = $ftp->dir("./organisms/");

my $con = 1;
my $total = @species_dir;
print "\n";
foreach (@species_dir) {
	my $species = (split(/\s/, $_))[-1];
	my $percent = sprintf("%5.2f", $con/$$);
	print "$percent\% finished, downloading species $species \.\.\.  \r";
	$ftp->get("./organisms/$species/$species.list") or die "get failed ", $ftp->message;
	$con++;
	my $cat = "cat $species.list  >> temp_all.map";
	system($cat);
	unlink("$species.list");
}
print "\n";
$ftp->quit;

my $dbh = DBI->connect("DBI:mysql:database=kegg;host=124.16.151.190","cafeblue", "bacdavid",{'RaiseError' => 1});
my $clean_table = "truncate table pathway_geneid_desc";
my $rows = $dbh->do($clean_table) or die $dbh->errstr;
open (ALL, "temp_all.map") or die $!;
while (<ALL>) {
	my @line = split(/\t/, $_);
	if ($line[1] =~ /cpd\:C\d+/ || $line[1] =~ /ds\:H\d+/ ) {
		next;
	}
	else {
		my $insert = "insert into pathway_geneid_desc VALUES (\"$line[0]\", \"$line[1]\", \"$line[2]\")";
		$dbh->do($insert) or die $dbh->errstr;
	}
}
unlink("temp_all.map");
