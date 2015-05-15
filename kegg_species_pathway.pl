#! /usr/bin/perl -w

# writen by Wei Wang, Oct. 12, 2010

# used to extract the fasta file from genes.pep of kegg.
#
# input file should be a config file. and the config file
# should contain the following columns:

#	#species
#   hsa	00010	hsa00010.fasta
#	hsa 00020	hsa00020.fasta
#	hsa 00561	hsa00561.fasta
#	#pathway
#	00010	pathway00010.fasta
#	00020	pathway00020.fasta
#	00030	pathway00030.fasta
#	00461	pathway00461.fasta

# in the species section, the first column should be the 
# three leter abbr. of genus and species name. the second
# column should be the pathway number you need. the third
# column should be the output file name.

# in the pathway section, the first column should be the
# pathway number you need, the second column should be the
# output file name. all the genes in all species will be
# extracted in this pathway and stored in the output file.

use strict;
use DBI();

if (@ARGV < 1) {
	print "\n\tUsage: $0 config_file";
	print "\n\tExample: $0 config\n";
	print "\n\tView this program file for the detailed information of config\n";
	exit(0);
}

open(LIST, "$ARGV[0]") or die $!;
my $dbh = DBI->connect("DBI:mysql:database=kegg;host=124.16.151.190","cafeblue", "bacdavid",{'RaiseError' => 1});
my $flag = 0;

while (<LIST>) {
	chomp;
	my @line = ();
	if (/^\#species/) {
		$flag = 1;
	}
	elsif (/^\#pathway/) {
		$flag = 2;
	}
	elsif ($flag == 1) {
		@line = split(/\t/, $_);
		my $query = "path\:".$line[0].$line[1];
		my @geneid = @{$dbh->selectall_arrayref("select geneid from pathway_geneid_desc where pathway like \"$query\"", { Slice => {} })};
		open (TMP, ">tmp.list");
		foreach my $gid (@geneid) {
			print TMP $gid->{geneid},"\n";
		}
		close(TMP);
		`fastacmd -i tmp.list -d /home/gene/bioinfo/data/bio_databases/kegg/genes.pep -o $line[2]`;
		unlink("tmp.list");
	}
	elsif ($flag == 2) {
		@line = split(/\t/, $_);
		my $query = 'path:%%%'.$line[0];
		my @geneid = @{$dbh->selectall_arrayref("select geneid from pathway_geneid_desc where pathway like \"$query\"", { Slice => {} })};
#		$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
#		if ($sth->rows == 0) {
#			print STDERR $sth->rows," rows found of pathway $line[0]\n";
#		next;
#		}
#		my @geneid = @{$sth->selectall_arrayref()};
		open (TMP, ">tmp1.list");
		foreach my $gid  (@geneid) {
			print TMP $gid->{geneid},"\n";
		}
		close(TMP);
		`fastacmd -i tmp1.list -d /home/gene/bioinfo/data/bio_databases/kegg/genes.pep -o $line[1]`;
		unlink("tmp1.list");
	}
	else {
		die "There is something wrong with you config file, check it carefully!\n";
	}
}
