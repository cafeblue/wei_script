#! /usr/bin/perl 

use strict;
use warnings;
use Encode;
use DBI;
use DBD::Oracle qw(:ora_fetch_orient :ora_exe_modes);
use File::Temp qw( tmpfile );

sub count_cycles_ga {
    open (TMP, "$_[0]") or print "$_[0] not exists!\n";
    my $cycle = 0;
    while (<TMP>) {
        if (/LastCycle\="(\d+)\"/) {
            $cycle = $1;
        }
    }
    close(TMP);
    return $cycle;
}

sub count_cycles_hi {
    open (TMP, "$_[0]") or print "$_[0] not exists!\n";
    my $cycle = 0; 
    while (<TMP>) {
        if (/NumCycles\=\"(\d+)\"/) {
            $cycle += $1;
        }
    }
    close(TMP);
    return $cycle;
}

sub count_runs {
    open (RUNS, "$_[0]") or warn "$_[0] not exists!\n";
    my $run = 0;
    while (<RUNS>) {
        if (/\<LastCycle\>(\d+)\<\/LastCycle\>/) {
            $run = $1;
        }
    }
    close(RUNS);
    return $run;
}

my %file_list_ga;
my %file_list_hi;
my @ga = `cat /home/wangw/.tmpgafile`;
my @hi = `cat /home/wangw/.tmphifile`;
foreach (@ga) {
    chomp;
    my @list = split(/\t/, $_);
    $file_list_ga{$list[0]} = $list[1];
}
foreach (@hi) {
    chomp;
    my @list = split(/\t/, $_);
    $file_list_hi{$list[0]} = $list[1];
}

my @ga_dirs = `ls -d /share/data1/GAdata/Runs/??????_HWUSI-EAS17??*_?????_???????????`;
my @hi_dirs = `ls -d /share/data1/Hisdata/Runs/??????_SN298_????_??????????`;
#open (GA, ">/home/wangw/.tmpgafile") or die $!;
#open (HI, ">/home/wangw/.tmphifile") or die $!;

my $tmpgafile = File::Temp->new( DIR => '/tmp' );
my $tmphifile = File::Temp->new( DIR => '/tmp' );

foreach my $dir (@ga_dirs) {
    chomp($dir);
    my $cycles = count_cycles_ga("$dir/RunInfo.xml");
    my $runs   = count_runs("$dir/Data/Intensities/BaseCalls/config.xml");
    if ($cycles == $runs && $file_list_ga{$dir} == 0) {
        run_parse($dir, "GA");
        print $tmpgafile $dir,"\t1\n";
    }
    elsif (not exists $file_list_ga{$dir}) {
        print $tmpgafile $dir,"\t0\n";
    }
    elsif ($file_list_ga{$dir} == 0) {
        print $tmpgafile $dir,"\t0\n";
    }
    else {
        print $tmpgafile $dir,"\t1\n";
    }
}

foreach my $dir (@hi_dirs) {
    chomp($dir);
    my $cycles = count_cycles_hi("$dir/RunInfo.xml");
    my $runs   = count_runs("$dir/Data/Intensities/BaseCalls/config.xml");
    if (not exists $file_list_hi{$dir}) {
        print $tmphifile $dir,"\t0\n";
    }
    elsif ($cycles == $runs && $file_list_hi{$dir} == 0) {
        run_parse($dir, "HI");
        print $tmphifile $dir,"\t1\n";
    }
    elsif ($file_list_hi{$dir} == 0) {
        print $tmphifile $dir,"\t0\n";
    }
    else {
        print $tmphifile $dir,"\t1\n";
    }
}

system ("cp $tmpgafile /home/wangw/.tmpgafile");
system ("cp $tmphifile /home/wangw/.tmphifile");

sub run_parse {
    (my $run_dir, my $type) = @_;
    $run_dir =~ s/.+\///;
    open (CSV, ">/tmp/$run_dir.csv") or die $!;
    if ($type eq "GA") {
        open (CONF, ">/tmp/$run_dir.config") or die $!;
        print CONF "FLOW_CELL 1.4mm\n";
        print CONF "ELAND_SET_SIZE 40\n";
    }
    my $run_id = (split(/_/,$run_dir))[-1];
	my $dbh = DBI->connect("dbi:Oracle:host=192.168.4.240;sid=ORCLLIMS", "BEIR", "BEIR");
    my $SQL = "SELECT A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.POOL_LIB_NAME AS POOL_LIB_NAME, A.QC_HHLLMD AS POOL_CONCENT, A.QC_HHTUL AS POOL_VOL, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_NAME AS LIB_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS Index_ID, A.LIB_BG_DATE AS LIB_TIME, A.TASK_DATA_TOTAL AS DATA_VOL, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS LIB_CONCENT FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME, A.FLOWCELL, B.LANE_NUMBER, NULL AS POOL_LIB_NAME, NULL AS QC_HHLLMD, NULL AS QC_HHTUL, B.LIB_ID, C.SAMPLE_MX_CODE, C.SAMPLE_MX_NAME, C.LIB_NAME, C.LIB_TYPE, C.LIB_QJ_LENGHT, TO_CHAR(C.LIB_INDEX_NO) AS LIB_INDEX_NO, TO_CHAR(C.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, D.TASK_DATA_TOTAL, F.PJ_CODE, F.PJ_NAME FROM CS_HS_INFO A , LANE_INFO B , LIB_INFO C , MIS_TASK_MX D , MIS_TASK E , PROJECT_INFO F WHERE A.FLOWCELL = '$run_id' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID AND B.LIB_ID = C.ID AND C.TASK_MX_ID = D.ID AND D.TASK_ID = E.ID AND E.PJ_ID = F.ID UNION ALL SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.POOL_INDEX_NO AS LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_CODE, B.PJ_NAME FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.POOL_INDEX_NO, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.POOL_INDEX_NO, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID, C.TASK_DATA_TOTAL FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.POOL_LIB_NAME, B.QC_HHLLMD, B.QC_HHTUL, C.LIB_ID, C.POOL_INDEX_NO FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME , A.FLOWCELL , B.LANE_NUMBER , B.LIB_ID FROM CS_HS_INFO A , LANE_INFO B WHERE A.FLOWCELL = '$run_id' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID ) A , LIB_INFO B WHERE A.LIB_ID = B.ID ) A , POOLING_MAIN B, POOLING_MX C WHERE A.LIB_POOL_ID = B.ID AND B.ID = C.POOL_ID ) A , LIB_INFO B, MIS_TASK_MX C WHERE A.LIB_ID = B.ID AND B.TASK_MX_ID = C.ID ) A , MIS_TASK B WHERE A.TASK_ID = B.ID ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.LIB_INDEX_NO ASC ";
#    my $SQL = "SELECT A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.POOL_LIB_NAME AS POOL_LIB_NAME, A.QC_HHLLMD AS CONCENTRTION_POOL, A.QC_HHTUL AS VOLUMN_POOL, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_NAME AS LIB_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS Index_ID, A.LIB_BG_DATE AS LIB_TIME, A.TASK_DATA_TOTAL AS DATA_TOTAL, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS LIB_CONCENTRATION FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME, A.FLOWCELL, B.LANE_NUMBER, NULL AS POOL_LIB_NAME, NULL AS QC_HHLLMD, NULL AS QC_HHTUL, B.LIB_ID, C.SAMPLE_MX_CODE, C.SAMPLE_MX_NAME, C.LIB_NAME, C.LIB_TYPE, C.LIB_QJ_LENGHT, C.LIB_INDEX_NO, TO_CHAR(C.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, D.TASK_DATA_TOTAL, F.PJ_CODE, F.PJ_NAME FROM CS_HS_INFO A , LANE_INFO B , LIB_INFO C , MIS_TASK_MX D , MIS_TASK E , PROJECT_INFO F WHERE A.FLOWCELL = '$run_id' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID AND B.LIB_ID = C.ID AND C.TASK_MX_ID = D.ID AND D.TASK_ID = E.ID AND E.PJ_ID = F.ID UNION ALL SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_CODE, B.PJ_NAME FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, A.TASK_DATA_TOTAL, B.PJ_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.POOL_LIB_NAME, A.QC_HHLLMD, A.QC_HHTUL, A.LIB_ID, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, B.LIB_INDEX_NO, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID, C.TASK_DATA_TOTAL FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.POOL_LIB_NAME, B.QC_HHLLMD, B.QC_HHTUL, C.LIB_ID FROM ( SELECT A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME , A.FLOWCELL , B.LANE_NUMBER , B.LIB_ID FROM CS_HS_INFO A , LANE_INFO B WHERE A.FLOWCELL = '$run_id' AND A.CSHS_FLAG = '1' AND A.ID = B.FLOWCELL_ID ) A , LIB_INFO B WHERE A.LIB_ID = B.ID ) A , POOLING_MAIN B, POOLING_MX C WHERE A.LIB_POOL_ID = B.ID AND B.ID = C.POOL_ID ) A , LIB_INFO B, MIS_TASK_MX C WHERE A.LIB_ID = B.ID AND B.TASK_MX_ID = C.ID ) A , MIS_TASK B WHERE A.TASK_ID = B.ID ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.LIB_INDEX_NO ASC ";
#	my $SQL = "SELECT  A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS INDEX_ID, A.LIB_BG_DATE AS LIB_TIME, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS CONCENTRATION FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_CODE, B.PJ_NAME FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, B.LIB_INDEX_NO, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_ID  FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT  TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME  , A.FLOWCELL  , B.LANE_NUMBER  , B.LIB_ID  FROM CS_HS_INFO A , LANE_INFO B  WHERE  A.FLOWCELL = '$run_id' AND A.ID = B.FLOWCELL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , POOLING_MX B WHERE A.LIB_POOL_ID = B.POOL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , MIS_TASK B WHERE A.TASK_ID = B.ID  ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID  ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID  ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.SAMPLE_MX_CODE ASC";
	
#my $SQL = "SELECT  A.HS_READ1_DATETIME AS ON_MACHINE_TIME, A.FLOWCELL AS FLOWCELL_ID, A.LANE_NUMBER AS LANE_ID, A.SAMPLE_MX_CODE AS SAMPLE_ID, A.SAMPLE_MX_NAME AS SAMPLE_NAME, A.LIB_TYPE AS LIB_TYPE, A.LIB_QJ_LENGHT AS LIB_SIZE, A.LIB_INDEX_NO AS INDEX_ID, A.LIB_BG_DATE AS LIB_TIME, A.PJ_CODE AS PRO_ID, A.PJ_NAME AS PRO_NAME, ( CASE B.CHQPCR_MER_JZ WHEN 0 THEN B.CHQPCR_MER ELSE B.CHQPCR_MER_JZ END ) AS CONCENTRATION FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_CODE, B.PJ_NAME FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, A.SAMPLE_MX_CODE, A.SAMPLE_MX_NAME, A.LIB_TYPE, A.LIB_QJ_LENGHT, A.LIB_INDEX_NO, A.LIB_BG_DATE, B.PJ_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL, A.LANE_NUMBER, A.LIB_ID, B.SAMPLE_MX_CODE, B.SAMPLE_MX_NAME, B.LIB_TYPE, B.LIB_QJ_LENGHT, B.LIB_INDEX_NO, TO_CHAR(B.LIB_BG_DATE, 'yyyy-mm-dd') AS LIB_BG_DATE, B.TASK_ID FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_ID  FROM ( SELECT  A.HS_READ1_DATETIME, A.FLOWCELL,  A.LANE_NUMBER, B.LIB_POOL_ID FROM ( SELECT  TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') AS HS_READ1_DATETIME  , A.FLOWCELL  , B.LANE_NUMBER  , B.LIB_ID  FROM CS_HS_INFO A , LANE_INFO B  WHERE  A.FLOWCELL IN ( SELECT FLOWCELL FROM CS_HS_INFO  WHERE TO_CHAR(A.HS_READ1_DATETIME, 'yyyy-mm-dd') = '$date' ) AND A.ID = B.FLOWCELL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , POOLING_MX B WHERE A.LIB_POOL_ID = B.POOL_ID  ) A , LIB_INFO B WHERE A.LIB_ID = B.ID  ) A , MIS_TASK B WHERE A.TASK_ID = B.ID  ) A , PROJECT_INFO B WHERE A.PJ_ID = B.ID  ) A LEFT JOIN CHECKQPCR B ON A.LIB_ID = B.LIB_ID  ORDER BY A.FLOWCELL ASC , A.LANE_NUMBER ASC , A.SAMPLE_MX_CODE ASC ";
	my $sth=$dbh->prepare($SQL);
	$sth->execute();
	my @row;
	my %csv;
	my %index = (
	"1" => "ATCACG",
	"2" => "CGATGT",
	"3" => "TTAGGC",
	"4" => "TGACCA",
	"5" => "ACAGTG",
	"6" => "GCCAAT",
	"7" => "CAGATC",
	"8" => "ACTTGA",
	"9" => "GATCAG",
	"10" => "TAGCTT",
	"11" => "GGCTAC",
	"12" => "CTTGTA",
	"13" => "TGTCGA",
	"14" => "GTGACA",
	"15" => "AATGCC",
	"16" => "CTAGAC",
	"17" => "CGGTAT",
	"18" => "TGCAAC",
	"19" => "GCATCA",
	"20" => "GAAGTC",
	"21" => "AGTCAA",
	"22" => "AGTTCC",
	"23" => "ATGTCA",
	"24" => "CCGTCC",
	"25" => "GTAGAG",
	"26" => "GTCCGC",
	"27" => "GTGAAA",
	"28" => "GTGGCC",
	"29" => "GTTTCG",
	"30" => "CGTACG",
	"31" => "GAGTGG",
	"32" => "GGTAGC",
	"33" => "ACTGAT",
	"34" => "ATGAGC",
	"35" => "ATTCCT",
	"36" => "CAAAAG",
	"37" => "CAACTA",
	"38" => "CACCGG",
	"39" => "CACGAT",
	"40" => "CACTCA",
	"41" => "CAGGCG",
	"42" => "CATGGC",
	"43" => "CATTTT",
	"44" => "CCAACA",
	"45" => "CGGAAT",
	"46" => "CTAGCT",
	"47" => "CTATAC",
	"48" => "CTCAGA",
	"49" => "GACGAC",
	"50" => "TAATCG",
	"51" => "TACAGC",
	"52" => "TATAAT",
	"53" => "TCATTC",
	"54" => "TCCCGA",
	"55" => "TCGAAG",
	"56" => "TCGGCA",
	"57" => "ACCTGA",
	"58" => "ACGCTT",
	"59" => "ATCGAC",
	"60" => "CAAGGC",
	"61" => "CCATAT",
	"62" => "CCTCGG",
	"63" => "CTTACC",
	"64" => "GCAATC",
	"65" => "GCGGAG",
	"66" => "GGACCG",
	"67" => "GGCGTT",
	"68" => "GGTTGC",
	"69" => "GTCAGG",
	"70" => "GTTCAT",
	"71" => "TCTGCT",
	"72" => "TGAAGT",
	"73" => "TGGTAA",
	"74" => "TTATTG",
	"75" => "TTGCGC",
	"GTC" => "76",
	"AGT" => "77",
	"CAG" => "78",
	"TCA" => "79",
	);
	
    print CSV "FCID,Lane,SampleID,SampleRef,Index,Description,Control,Recipe,Operator,SampleProject";
    my %csv_file;
	while ((@row) = $sth->fetchrow()) {
        if ($row[1] && $row[2] && ($row[9] =~ /\xB2\xFA\xC7\xB0/) ) {
            if (! $row[11]) {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[8],prenatal,,p,N,R2,wangw,All";
            }
            elsif (exists $index{$row[11]}) {
                $csv_file{"$row[2]"} .= "\n$row[1],$row[2],$row[8],prenatal,$index{$row[11]},p,N,R2,wangw,All";
            }
            else {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[8],prenatal,,p,N,R2,wangw,All";
            }
        }
        elsif ($row[1] && $row[2] && (not $row[7] =~ /[\x80-\xff]/) ) {
            if (! $row[11]) {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[7],none,,p,N,R2,wangw,All";
            }
            elsif (exists $index{$row[11]}) {
                $csv_file{"$row[2]"} .= "\n$row[1],$row[2],$row[7],none,$index{$row[11]},p,N,R2,wangw,All";
            }
            else {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[7],none,,p,N,R2,wangw,All";
            }
        }
        elsif ($row[1] && $row[2] && (not $row[6] =~ /\?/) )  {
            if (! $row[11]) {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[7],none,,p,N,R2,wangw,All";
            }
            elsif (exists $index{$row[11]}) {
                $csv_file{"$row[2]"} .= "\n$row[1],$row[2],$row[6],none,$index{$row[11]},p,N,R2,wangw,All";
            }
            else {
                $csv_file{"$row[2]"} = "\n$row[1],$row[2],$row[6],none,,p,N,R2,wangw,All";
            }
        }
        else {
            system("mail -s \'Sample Name or Sample ID illegal or lane id or runid error!\' wangwei\@berrygenomics.com < /home/wangw/info.txt");
            exit(0);
        }
	}
    for (1..8) {
        if (exists $csv_file{"$_"}) {
            if (not $csv_file{"$_"} =~ /,p,N,R2,wangw,.*\n.*,p,N,R2,wangw,/) {
                $csv_file{"$_"} =~ s/,[ATGC]{6},p,N,R2,wangw,All/,,p,N,R2,wangw,All/;
			}
            print CSV $csv_file{"$_"};
        }
        else {
            system("mail -s \'index info of lane $_ missing!\' wangwei\@berrygenomics.com < /home/wangw/info.txt");
            exit(0);
        }
    }
#    print "$run_dir start...";
	system("mail -s \"$run_dir start...\" wangwei\@berrygenomics.com < /home/wangw/info.txt");
    if ($type eq "GA") {
        system ("mv /tmp/$run_dir.* /home/wangw/BaseCall/GA/todo/");
    }
    else {
        system ("mv /tmp/$run_dir.* /home/wangw/BaseCall/HiSeq/todo/");
    }
}
