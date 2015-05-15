#! /usr/bin/perl -w
#
#input file is the list of your taxonomy name.
#output file contains the following four columns:
#
#1. your name
#2. taxid of your name
#3. name of your requested rate;
#4. taxid or your requested rate;

use strict;
use warnings;
use DBI();

if (@ARGV < 3) {
	print "\n\tUsage: $0 infile_list rate outfile";
	print "\n\tExample: $0 taxlist phylum output\n";
	exit(0);
}

open (INF, "$ARGV[0]") or die $!;
open (OUF, ">$ARGV[2]") or die $!;
print OUF "your_name\tyour_id\t$ARGV[1]\tid_of_$ARGV[1]\n";

# connect the mysql database in begc and read the database of taxonomy
my $dbh = DBI->connect("DBI:mysql:database=ncbi_taxonomy;host=124.16.151.190","cafeblue", "bacdavid",{'RaiseError' => 1});

while (<INF>) {
	chomp;
	my $your_name = $_;
	my $mysql_command = "SELECT \* FROM sci_name where scientific_name = \"$your_name\"";
    my $sth = $dbh->prepare("$mysql_command") or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
	if ($sth->rows == 0) {
            print STDERR "0 rows found of $your_name\n";
			print OUF $your_name,"\tYour name not found!\n";
            next;
	}
	print STDERR $sth->rows," rows found of $your_name\n";
    my $ref = $sth->fetchrow_hashref();
#	if (@ref < 1) {
#		print "ERROR!";
#		exit(0);
#	}
#	foreach (@ref) {
#		print $_,"\n";
#	}
	my $id = $ref->{'tax_id'};
	my $father_id = $id;
	print OUF $your_name,"\t",$id,"\t";
	while (1) {
		my $mysql_command1 = "SELECT tax_id,father_id,rate_name FROM tax_node where tax_id = \"$father_id\"";
#		print $mysql_command1,"\n";
		my $sth1 = $dbh->prepare("$mysql_command1") or die "Couldn't prepare statement: " . $dbh->errstr;
		$sth1->execute() or die "Couldn't execute statement: " . $sth1->errstr;
		if ($sth1->rows == 0) {
			print STDERR $sth1->rows," rows found of ID $father_id\n";
			last;
		}
		my $ref1 = $sth1->fetchrow_hashref();
		if ($ref1->{'rate_name'} eq $ARGV[1]) {
			my $mysql_command2 = "SELECT scientific_name FROM sci_name where tax_id = \"".$ref1->{'tax_id'}."\"";
			my $sth2 = $dbh->prepare("$mysql_command2") or die "Couldn't prepare statement: " . $dbh->errstr;
			$sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
			my $ref2 = $sth2->fetchrow_hashref();
			print OUF $ref2->{'scientific_name'},"\t",$father_id,"\n";
			last;
		}
		elsif ($ref1->{'father_id'} == 1) {
			print OUF "not found!\n";
			last;
		}
		$father_id = $ref1->{'father_id'};
	}
}

