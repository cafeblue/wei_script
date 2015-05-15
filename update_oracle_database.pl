#! /usr/bin/perl -w

use strict;
use DBI;
use DBD::Oracle qw(:ora_fetch_orient :ora_exe_modes);

my $dbh = DBI->connect("dbi:Oracle:host=192.168.4.240;sid=ORCLLIMS", "BEIR", "BEIR");

my $machine = "abc";
my $chip = "def";

my $SQL = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, INDEX_RATIO) VALUES ( 1, '$machine', '$chip', 6, 12, 120, 207, 20200000, 22, 56, 90, 80, 100000, 89, 100, 12345)";

my $sth=$dbh->prepare($SQL);
$sth->execute();

$SQL = "delete from SOLEXA_DATA where HTML_FILE = 12345";
$sth=$dbh->prepare($SQL);
$sth->execute();

#$SQL = "select ID, MACHINE_NUMBER, CHIP_NUMBER from SOLEXA_DATA";
#$sth=$dbh->prepare($SQL,{ora_exe_mode=>OCI_STMT_SCROLLABLE_READONLY});
#$sth->execute();
#my $value;

#$value =  $sth->ora_fetch_scroll(OCI_FETCH_LAST,-1);
#print "ID=".$value->[0].", First Name=".$value->[1].", Last Name=".$value->[2]."\n";
#print "current scroll position=".$sth->ora_scroll_position()."\n";


if ($ARGV[0] eq "GA") {
    my ($machine_number, $chip_number) = (split(/_/, $id))[1,3];
    
}
elsif ($ARGV[0] eq "HiSeq") {
    my ($machine_number, $chip_number) = (split(/_/, $id))[1,3];
}
else {
    die "please set the run type as GA or Hiseq";
}
