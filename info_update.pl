#! /usr/bin/perl 
##! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use Encode;
use DBI;
use DBD::Oracle qw(:ora_fetch_orient :ora_exe_modes);

my $dbh = DBI->connect("dbi:Oracle:host=192.168.4.240;sid=ORCLLIMS", "BEIR", "BEIR");
my $orc_run_id = (split(/\//, $ARGV[0]))[-1];
my ($orc_machine_number, $orc_chip_number) = (split(/_/,$orc_run_id))[1,3];

my $orc_cycle = 0;
my $orc_reads_length = 0;

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

my %stat;
my @reads_stat =  `cat $ARGV[0]/reads_stat.txt`;
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

if ($ARGV[1] eq "GA") {
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
            my ($dir_tmp, $lane_tmp);
    		$id =~ s/.+(\d{3})\/(s_\d).+/$1_$2/;
            $dir_tmp = $1;
            $lane_tmp = $2;
    		my $tmp_lane = $2;
    		$tmp_lane =~ s/s_//;
    		$known{$tmp_lane} += $tmp1[1];
    		$stat{$id} = {'reads' => $tmp1[1], 'bases' => $tmp1[2], 'ratio' => $tmp1[3], 'lane' => $tmp_lane , 'index' => $1, 'Q30' => $tmp1[4], 'Q20' => $tmp1[5], 'pf_cluster' => $tmp1[6], 'raw_cluster' => $tmp1[7], 'gc' => $tmp1[8], 'figer' => "$orc_run_id\\$dir_tmp\_$lane_tmp\_s.png"};
            if ($ARGV[2] =~ /True/) {
                $stat{$id}{'figer'} = "$orc_run_id\\$dir_tmp\_s_$lane_tmp\_1.png,$orc_run_id\\$dir_tmp\_$lane_tmp\_2.png";
            }
    	}
    }
    my @sample_sheet_file = `find $ARGV[0] -name Samples*.csv -exec cat {} \\;`;
    foreach (@sample_sheet_file) {
    	chomp;
    	if (/^FCID,Lane,SampleID,SampleRef,/) {
    		next;
    	}
    	my ($lane, $index, $dir) = (split(/,/, $_))[1,4,9];
    	my $new_id = $dir."_s_".$lane;
    	if (exists $stat{$new_id}) {
    		$stat{$new_id}{'index'} = $index;
    		$stat{$new_id}{'html'} = "$orc_run_id\\Summary_$dir.htm";
    	}
    }
}
elsif ($ARGV[1] eq "HiSeq") {
    foreach (@reads_stat) {
    	chomp;
    	my @tmp1 = split(/\s+/, $_);
    	my $id = $tmp1[0];
    	if ($id =~ m/Undetermined_L00(\d)/) {
    		if (exists $unkno{$1}) {
    			die "More than one unknown id exists!\n";
    		}
    		else {
    			$unkno{$1} = $tmp1[1];
    		}
    	}
    	else {
            my ($index_tmp, $lane_tmp, $name_tmp);
    		if ($id =~ m/.+\/(.+)_(\w+)_L00(\d)_R1_001\.fastq\.gz$/) {
                $index_tmp = $2;
                $lane_tmp = $3;
                $name_tmp = $1;
    			$known{$3} += $tmp1[1];
    			$stat{$id} = {'reads' => $tmp1[1], 'bases' => $tmp1[2], 'ratio' => $tmp1[3], 'lane' => $3 , 'index' => $2, 'Q30' => $tmp1[4], 'Q20' => $tmp1[5], 'pf_cluster' => $tmp1[6], 'raw_cluster' => $tmp1[7], 'gc' => $tmp1[8], 'html' => "$orc_run_id\\Demultiplex_Stats.htm", 'figer' => "$orc_run_id\\$1_$2_L00$3_R1_base_quality.png"};
               if ($ARGV[2] =~ /True/) {
                   $stat{$id}{'figer'} .= ",$orc_run_id\\$name_tmp\_$index_tmp\_L00$lane_tmp\_R2_base_quality.png";
               }
    		}
    		else {
    			die "reads_stat.txt file is abnormal!\n";
    		}
    	}
    }
}

foreach (1..8) {
    if (exists $unkno{$_}) {
    	$unknown_rate{$_} = sprintf('%6.3f', $unkno{$_} * 100 / ($unkno{$_}+$known{$_})) . '%';
    }
    else {
        $unknown_rate{$_} = '0.000%';
    }
}

#my $SQL = "SELECT A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS INDEX_ID, A.LIB_BG_DATE AS LIB_TIME, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS CONCENTRATION FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_CODE, B.PJ_NAME FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, B.LIB_INDEX_NO, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_ID  FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT  TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME  , A.FLOWCELL  , B.LANE_NUMBER  , B.LIB_ID  FROM CS_HS_INFO A , LANE_INFO B  WHERE  A.FLOWCELL = '$orc_chip_number' AND A.ID = B.FLOWCELL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , POOLING_MX B WHERE A.LIB_POOL_ID = B.POOL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , MIS_TASK B WHERE A.TASK_ID = B.ID  ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID  ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID  ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.SAMPLE_MX_CODE ASC";
#my $SQL = "SELECT A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.POOL_LIB_NAME AS POOL_LIB_NAME, A.QC_HHLLMD AS CONCENTRTION_POOL, A.QC_HHTUL AS VOLUMN_POOL, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_NAME AS LIB_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS Index_ID, A.LIB_BG_DATE AS LIB_TIME, A.TASK_DATA_TOTAL AS DATA_TOTAL, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS LIB_CONCENTRATION FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME, A.FLOWCELL, B.LANE_NUMBER, NULL AS POOL_LIB_NAME, NULL AS QC_HHLLMD, NULL AS QC_HHTUL, B.LIB_ID, C.SAMPLE_MX_CODE, C.SAMPLE_MX_NAME, C.LIB_NAME, C.LIB_TYPE, C.LIB_QJ_LENGHT, C.LIB_INDEX_NO, TO_CHAR(C.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, D.TASK_DATA_TOTAL, F.PJ_CODE, F.PJ_NAME FROM CS_HS_INFO A , LANE_INFO B , LIB_INFO C , MIS_TASK_MX D , MIS_TASK E , PROJECT_INFO F WHERE A.FLOWCELL = '$orc_chip_number' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID AND B.LIB_ID = C.ID AND C.TASK_MX_ID = D.ID AND D.TASK_ID = E.ID AND E.PJ_ID = F.ID UNION ALL SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_CODE, B.PJ_NAME FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, B.LIB_INDEX_NO, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID, C.TASK_DATA_TOTAL FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.POOL_LIB_NAME, B.QC_HHLLMD, B.QC_HHTUL, C.LIB_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME , A.FLOWCELL , B.LANE_NUMBER , B.LIB_ID FROM CS_HS_INFO A , LANE_INFO B WHERE A.FLOWCELL = '$orc_chip_number' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID ) A , LIB_INFO B WHERE A.LIB_ID = B.ID ) A , POOLING_MAIN B, POOLING_MX C WHERE A.LIB_POOL_ID = B.ID AND B.ID = C.POOL_ID ) A , LIB_INFO B, MIS_TASK_MX C WHERE A.LIB_ID = B.ID AND B.TASK_MX_ID = C.ID ) A , MIS_TASK B WHERE A.TASK_ID = B.ID ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.LIB_INDEX_NO ASC ";
my $SQL = "SELECT A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.POOL_LIB_NAME AS POOL_LIB_NAME, A.QC_HHLLMD AS POOL_CONCENT, A.QC_HHTUL AS POOL_VOL, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_NAME AS LIB_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS Index_ID, A.LIB_BG_DATE AS LIB_TIME, A.TASK_DATA_TOTAL AS DATA_VOL, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS LIB_CONCENT FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME, A.FLOWCELL, B.LANE_NUMBER, NULL AS POOL_LIB_NAME, NULL AS QC_HHLLMD, NULL AS QC_HHTUL, B.LIB_ID, C.SAMPLE_MX_CODE, C.SAMPLE_MX_NAME, C.LIB_NAME, C.LIB_TYPE, C.LIB_QJ_LENGHT, TO_CHAR(C.LIB_INDEX_NO) AS LIB_INDEX_NO, TO_CHAR(C.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, D.TASK_DATA_TOTAL, F.PJ_CODE, F.PJ_NAME FROM CS_HS_INFO A , LANE_INFO B , LIB_INFO C , MIS_TASK_MX D , MIS_TASK E , PROJECT_INFO F WHERE A.FLOWCELL = '$orc_chip_number' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID AND B.LIB_ID = C.ID AND C.TASK_MX_ID = D.ID AND D.TASK_ID = E.ID AND E.PJ_ID = F.ID UNION ALL SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.POOL_INDEX_NO AS LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_CODE, B.PJ_NAME FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.POOL_INDEX_NO, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.POOL_INDEX_NO, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID, C.TASK_DATA_TOTAL FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.POOL_LIB_NAME, B.QC_HHLLMD, B.QC_HHTUL, C.LIB_ID, C.POOL_INDEX_NO FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME , A.FLOWCELL , B.LANE_NUMBER , B.LIB_ID FROM CS_HS_INFO A , LANE_INFO B WHERE A.FLOWCELL = '$orc_chip_number' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID ) A , LIB_INFO B WHERE A.LIB_ID = B.ID ) A , POOLING_MAIN B, POOLING_MX C WHERE A.LIB_POOL_ID = B.ID AND B.ID = C.POOL_ID ) A , LIB_INFO B, MIS_TASK_MX C WHERE A.LIB_ID = B.ID AND B.TASK_MX_ID = C.ID ) A , MIS_TASK B WHERE A.TASK_ID = B.ID ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.LIB_INDEX_NO ASC ";
my $sth=$dbh->prepare($SQL);
$sth->execute();
my @row;

while ((@row) = $sth->fetchrow()) {
	foreach (keys %stat) {
		if ($stat{$_}{'index'} eq "NoIndex") {
			if ($stat{$_}{'lane'} eq $row[2]) {
                $stat{$_}{reads} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
                $stat{$_}{raw_cluster} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
                $stat{$_}{bases} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
                $stat{$_}{pf_cluster} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
                my $SQL1 = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, CLUSTER_CLEAN, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, UNKNOWN_RATIO, CLEAN_BASES_NUM, FIGURE_FILE) VALUES ( '$orc_run_id', '$orc_machine_number', '$orc_chip_number', '$row[2]', '$row[11]', 32, '$orc_cycle', '$stat{$_}{raw_cluster}', '$stat{$_}{reads}', 'unknown', '$stat{$_}{gc}', '$stat{$_}{Q20}', '$stat{$_}{Q30}', '$stat{$_}{pf_cluster}', 'unknown', '$orc_reads_length', '$stat{$_}{html}', '$stat{$_}{ratio}', '0.000%', '$stat{$_}{bases}', '$stat{$_}{figer}')";
                my $sth=$dbh->prepare($SQL1);
                $sth->execute();
	    	}
		}
		elsif ($index_list{$stat{$_}{'index'}} eq $row[11] && $stat{$_}{'lane'} eq $row[2]) {
	    	my $reads_ratio = sprintf('%6.3f', $stat{$_}{'reads'}*100/$known{$stat{$_}{'lane'}}).'%';
            $stat{$_}{reads} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
            $stat{$_}{raw_cluster} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
            $stat{$_}{bases} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
            $stat{$_}{pf_cluster} =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
            my $SQL1 = "INSERT INTO SOLEXA_DATA (ID, MACHINE_NUMBER, CHIP_NUMBER, LANE, INDEX_NUM, TILE_SUM, CYCLE_SUM, CLUSTER_RAW, CLUSTER_CLEAN, ERROR_PERCENT_REGEUST, GC_PERCENT, Q20_PERCENT, Q30_PERCENT, PFCLUSTERS, ALIGN_PE, READ_LENGTH, HTML_FILE, CLEAN_RATIO, UNKNOWN_RATIO, CLEAN_BASES_NUM, FIGURE_FILE) VALUES ( '$orc_run_id', '$orc_machine_number', '$orc_chip_number', '$row[2]', '$index_list{$stat{$_}{'index'}}', 32, '$orc_cycle', '$stat{$_}{raw_cluster}', '$stat{$_}{reads}', 'unknown', '$stat{$_}{gc}', '$stat{$_}{Q20}', '$stat{$_}{Q30}', '$stat{$_}{pf_cluster}', 'unknown', '$orc_reads_length', '$stat{$_}{html}', '$stat{$_}{ratio}', '$unknown_rate{$stat{$_}{lane}}', '$stat{$_}{bases}', '$stat{$_}{figer}')";
            my $sth=$dbh->prepare($SQL1);
            $sth->execute();
		}
	}
}

