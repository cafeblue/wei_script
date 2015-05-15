#! /usr/bin/perl -w

use strict;
use Excel::Writer::XLSX;
use Spreadsheet::XLSX;
use Encode;
use DBI;
use DBD::Oracle qw(:ora_fetch_orient :ora_exe_modes);

my $ver = 0.1;
my $usage=<<"USAGE";
        Program : $0
        Version : $ver
        Contact : Wang Wei
        Usage : $0 dir1 dir2
                dir1       directory which  .xlsx file exists;
                dir2       directory which  reads_stat.txt exists; 

USAGE
die $usage unless @ARGV == 2;

my $dbh = DBI->connect("dbi:Oracle:host=192.168.4.240;sid=ORCLLIMS", "BEIR", "BEIR");
my $orc_run_id = (split(/\//, $ARGV[0]))[-1];
my ($orc_machine_number, $orc_chip_number) = (split(/_/,$orc_run_id))[1,3];

my $orc_cycle = 0;
my $orc_reads_length = 0;

#my $SQL = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, INDEX_RATIO) VALUES ( 1, '$machine', '$chip', 6, 12, 120, 207, 20200000, 22, 56, 90, 80, 100000, 89, 100, 12345, 'test', 'test')";

#my $sth=$dbh->prepare($SQL);
#$sth->execute();

my %index_list = (
"ATCACG" => "1",
"CGATGT" => "2",
"TTAGGC" => "3",
"TGACCA" => "4",
"ACAGTG" => "5",
"GCCAAT" => "6",
"CAGATC" => "7",
"ACTTGA" => "8",
"GATCAG" => "9",
"TAGCTT" => "10",
"GGCTAC" => "11",
"CTTGTA" => "12",
"TGTCGA" => "13",
"GTGACA" => "14",
"AATGCC" => "15",
"CTAGAC" => "16",
"CGGTAT" => "17",
"TGCAAC" => "18",
"GCATCA" => "19",
"GAAGTC" => "20",
"AGTCAA" => "21",
"AGTTCC" => "22",
"ATGTCA" => "23",
"CCGTCC" => "24",
"GTAGAG" => "25",
"GTCCGC" => "26",
"GTGAAA" => "27",
"GTGGCC" => "28",
"GTTTCG" => "29",
"CGTACG" => "30",
"GAGTGG" => "31",
"GGTAGC" => "32",
"ACTGAT" => "33",
"ATGAGC" => "34",
"ATTCCT" => "35",
"CAAAAG" => "36",
"CAACTA" => "37",
"CACCGG" => "38",
"CACGAT" => "39",
"CACTCA" => "40",
"CAGGCG" => "41",
"CATGGC" => "42",
"CATTTT" => "43",
"CCAACA" => "44",
"CGGAAT" => "45",
"CTAGCT" => "46",
"CTATAC" => "47",
"CTCAGA" => "48",
"GACGAC" => "49",
"TAATCG" => "50",
"TACAGC" => "51",
"TATAAT" => "52",
"TCATTC" => "53",
"TCCCGA" => "54",
"TCGAAG" => "55",
"TCGGCA" => "56",
"ACCTGA" => "57",
"ACGCTT" => "58",
"ATCGAC" => "59",
"CAAGGC" => "60",
"CCATAT" => "61",
"CCTCGG" => "62",
"CTTACC" => "63",
"GCAATC" => "64",
"GCGGAG" => "65",
"GGACCG" => "66",
"GGCGTT" => "67",
"GGTTGC" => "68",
"GTCAGG" => "69",
"GTTCAT" => "70",
"TCTGCT" => "71",
"TGAAGT" => "72",
"TGGTAA" => "73",
"TTATTG" => "74",
"TTGCGC" => "75",
"GTC" => "76",
"AGT" => "77",
"CAG" => "78",
"TCA" => "79",
);

my $infile_dir = $ARGV[0];
$infile_dir =~ s/ /\\ /g;
print "Input dir: $infile_dir\n";
my $infile = `ls -rt $infile_dir/*.xlsx |head -1`;
chomp($infile);
my %stat;

my @reads_stat =  `ssh  wangw\@cluster "cat $ARGV[1]/reads_stat.txt"`;
shift(@reads_stat);
$orc_cycle = shift(@reads_stat);
$orc_cycle =~ s/.+\t//;
$orc_reads_length = shift(@reads_stat);
$orc_reads_length =~ s/.+\t//;
chomp($orc_cycle);
chomp($orc_reads_length);
my %unknown_rate;
my %known;
my %unkno;

foreach (@reads_stat) {
	chomp;
	my @tmp1 = split(/\s+/, $_);
	my $id = $tmp1[0];
	if ($id =~ m/unknown\/s_(\d)/) {
		if (exists $unkno{$1}) {
			die "More than one unknown id exists!\n";
		}
		else {
			$unkno{$1} = $tmp1[1];
		}
	}
	else {
		$id =~ s/.+(\d{3})\/(s_\d).+/$1_$2/;
		my $tmp_lane = $2;
		$tmp_lane =~ s/s_//;
		$known{$tmp_lane} += $tmp1[1];
		$stat{$id} = {'reads' => $tmp1[1], 'bases' => $tmp1[2], 'ratio' => $tmp1[3], 'lane' => $tmp_lane , 'index' => $1, 'Q30' => $tmp1[4], 'Q20' => $tmp1[5], 'pf_cluster' => $tmp1[6], 'raw_cluster' => $tmp1[7], 'gc' => $tmp1[8]};
	}
}

foreach (keys %unkno) {
	$unknown_rate{$_} = sprintf('%6.3f', $unkno{$_} * 100 / ($unkno{$_}+$known{$_})) . '%';
}

my @sample_sheet_file = `ssh wangw\@cluster "find $ARGV[1] -name Samples*.csv -exec cat {} \\;"`;
foreach (@sample_sheet_file) {
	chomp;
	if (/^FCID,Lane,SampleID,SampleRef,/) {
		next;
	}
	my ($lane, $index, $dir) = (split(/,/, $_))[1,4,9];
	my $new_id = $dir."_s_".$lane;
	if (exists $stat{$new_id}) {
		$stat{$new_id}{'index'} = $index;
		$stat{$new_id}{'html'} = "Summary_$dir.htm";
	}
}

my $my_format;
my $my_head;

my $excel = Spreadsheet::XLSX -> new ( $infile );
foreach my $sheet (@{$excel -> {Worksheet}}) {
    $sheet -> {MaxRow} ||= $sheet -> {MinRow};
    foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
        $sheet -> {MaxCol} ||= $sheet -> {MinCol};
		if ($row > 0) {
#			print $sheet->{Cells}[$row][4]->{Val},"\t",$sheet->{Cells}[$row][5]->{Val},"\n";
			foreach (keys %stat) {
				if ($stat{$_}{'index'} eq "NoIndex") {
					if ($stat{$_}{'lane'} eq $sheet->{Cells}[$row][5]->{Val}) {
                        my $SQL = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, CLUSTER_CLEAN, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, UNKNOWN_RATIO, CLEAN_BASES_NUM) VALUES ( '$orc_run_id', '$orc_machine_number', '$orc_chip_number', '$sheet->{Cells}[$row][5]->{Val}', '', 32, '$orc_cycle', '$stat{$_}{raw_cluster}', '$stat{$_}{reads}', 'unknown', '$stat{$_}{gc}', '$stat{$_}{Q20}', '$stat{$_}{Q30}', '$stat{$_}{pf_cluster}', 'unknown', '$orc_reads_length', 'Demultiplex_Stats.htm', '$stat{$_}{ratio}', '0.000%', '$stat{$_}{bases}')";
                        my $sth=$dbh->prepare($SQL);
                        $sth->execute();
					}
				}
				elsif (($stat{$_}{'index'} eq $sheet->{Cells}[$row][4]->{Val} || $index_list{$stat{$_}{'index'}} eq $sheet->{Cells}[$row][4]->{Val} ) && $stat{$_}{'lane'} eq $sheet->{Cells}[$row][5]->{Val}) {
					my $reads_ratio = sprintf('%6.3f', $stat{$_}{'reads'}*100/$known{$stat{$_}{'lane'}}).'%';
                    my $SQL = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, CLUSTER_CLEAN, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, UNKNOWN_RATIO, CLEAN_BASES_NUM) VALUES ( '$orc_run_id', '$orc_machine_number', '$orc_chip_number', '$sheet->{Cells}[$row][5]->{Val}', '$index_list{$stat{$_}{'index'}}', 32, '$orc_cycle', '$stat{$_}{raw_cluster}', '$stat{$_}{reads}', 'unknown', '$stat{$_}{gc}', '$stat{$_}{Q20}', '$stat{$_}{Q30}', '$stat{$_}{pf_cluster}', 'unknown', '$orc_reads_length', 'Demultiplex_Stats.htm', '$stat{$_}{ratio}', '$unknown_rate{$stat{$_}{lane}}', '$stat{$_}{bases}')";
                    my $sth=$dbh->prepare($SQL);
                    $sth->execute();
				}
			}
		}
    }
}

