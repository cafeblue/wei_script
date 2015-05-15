#! /bin/env perl 

use strict;
use warnings;

use Getopt::Long;
use PerlIO::gzip;
#use threads;
use DBI();
use Excel::Writer::XLSX;
use Spreadsheet::XLSX;
use Bio::SeqIO;
$|++;
##################################################
# Example of config.txt file:
#
# $ cat config.txt
#
# [lib_se]
# q=./sample1.fq.gz
#
# [lib_se]
# q=./sample2.fq.gz
#
# [lib_pe]
# q1=./sample3_read1.fq.gz
# q2=./sample3_read2.fq.gz
#
# [lib_pe]
# q1=./sample4_read1.fq.gz
# q2=./sample4_read2.fq.gz
#
# [database]
# DB_NT=/share/data/database/NT/nt 
# DB_SW=/share/data/database/Uniprot/uniprot_sprot.fasta
#
#
####################################

my $usage = <<"USAGE";

        Program : $0                                                                                                                                           
        Contact : Wang Wei                                                                                                                                     
        Usage : $0 [options]
                default config name "config.txt"                                                                                                                                  
        Example1: $0
        Example2: $0 -s myconfig.txt

USAGE



my %opts;
my $config_file = "config.txt";
GetOptions(\%opts,"s:s");
$config_file = $opts{s} if $opts{s};
open (CONF, "$config_file") or die $usage;
my @seq_files;
my @seq_files2 = ();
my $db_nt = "/share/data/database/NT/nt";
my $db_sw = "/share/data/database/Uniprot/uniprot_sprot.fasta";

while (<CONF>) {
    chomp;
    if (/\[lib_se\]/) {
        my $line = <CONF>;
        chomp($line);
        $line =~ s/.+\=//;
        push @seq_files, $line;
    }
    elsif (/\[lib_pe\]/) {
        my $line = <CONF>;
        chomp($line);
        $line =~ s/.+\=//;
        my $line1 = <CONF>;
        chomp($line1);
        $line1 =~ s/.+\=//;
        $line .= " $line1";
        push @seq_files2, $line;
    }
    elsif (/^DB_NT=(.+)/) {
        $db_nt = $1;
    }
    elsif (/^DB_SW=(.+)/) {
        $db_sw = $1;
    }
}

my ($opt_vh, $lib_num);
my $opt_oa = "";

for (0..$#seq_files2) {
    $lib_num = $_ + 1;
    my $shuffle = "shuffle$_.fq.gz";
    if ($lib_num == 1) {
        $opt_vh = "-shortPaired -fastq.gz $shuffle"; 
        $opt_oa = "-ins_length NNN -ins_length_sd DDD";
    }
    else {
        $opt_vh .= " -shortPaired$lib_num -fastq.gz $shuffle"; 
        $opt_oa .= " -ins_length$lib_num NNN -ins_length$lib_num\_sd DDD";
    }
#    system("shuffleSequences_fastq_gz.pl $seq_files2[$_] $shuffle");
}

foreach (@seq_files) {
    $lib_num++;
    $opt_vh .= " -short$lib_num -fastq.gz $_";
}

system("VelvetOptimiser.pl --s 31 --t 4 --d oases_ass --p velvetopt --o \'-read_trkg yes\' --f \'$opt_vh\' 1\> velvetopt.log 2\> velvetopt.err");

my @log = `tail -20 oases_ass/velvetopt_logfile.txt`;
my $start = 0;
foreach (@log) {
    if (/^Paired Library insert stats:$/) {
        $start = 1;
        next;
    }
    if (/^Paired-end library $start has length: (\d+),.+?(\d+)$/) {
        my $nnn = $1;
        my $ddd = $2;
        $opt_oa =~ s/NNN/$nnn/;
        $opt_oa =~ s/DDD/$ddd/;
        $start++;
    }
}


#system("oases oases_ass $opt_oa");

#system("blastall -p blastn -d $db_nt -e 1e-20 -a 16 -b 10 -m 9 -i ./oases_ass/transcripts.fa -o trans2nt.blastn");
#system("blastall -p blastx -d $db_sw -e 1e-20 -a 16 -b 10 -m 9 -i ./oases_ass/transcripts.fa -o trans2sw.blastx");
my %transcriptome;
my $dbh1 = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
open (NTB, "trans2nt.blastn") or die $!;
while (my $blast_lines = <NTB>) {
    if ($blast_lines =~ /^# Fields: Query/) {
        $blast_lines = <NTB>;
        if ($blast_lines =~ /^# /) {
            next;
    			}
        my ($query_name, $hit_id, $hit_evalue) = (split(/\t/, $blast_lines))[0,1,10];
        $transcriptome{$query_name}{'nt_id'} = $hit_id;
        $transcriptome{$query_name}{'nt_ev'} = $hit_evalue;
        $hit_id =~ s/gi\|//;
        $hit_id =~ s/\|.+//;
        my $sth = $dbh1->prepare("SELECT description FROM gene_annotation.nt_desc WHERE gi = \'$hit_id\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        $transcriptome{$query_name}{'nt_desc'} = pop(@row);
        $sth = $dbh1->prepare("SELECT goid from gene_annotation.gi2go WHERE gi = \'$hit_id\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        $transcriptome{$query_name}{'go'} = join('; ', @row);
    }
}
close(NTB);
open (NTB, "trans2sw.blastx") or die $!;
while (my $blast_lines = <NTB>) {
    if ($blast_lines =~ /^# Fields: Query/) {
        $blast_lines = <NTB>;
        last unless $blast_lines;
        if ($blast_lines =~ /^# /) {
            next;
    			}
        my ($query_name, $hit_id, $hit_evalue) = (split(/\t/, $blast_lines))[0,1,10];
        $transcriptome{$query_name}{'sw_id'} = $hit_id;
        $transcriptome{$query_name}{'sw_ev'} = $hit_evalue;
        $hit_id =~ s/sp\|//;
        $hit_id =~ s/\|.+//;
        my $sth = $dbh1->prepare("SELECT description FROM gene_annotation.sw_desc WHERE sp = \'$hit_id\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        $transcriptome{$query_name}{'sw_desc'} = pop(@row);
    }
}
close(NTB);

my $excel_newt = Excel::Writer::XLSX -> new ( "Transcript_Anno.xlsx" );
my $sheet_newt = $excel_newt->add_worksheet( "Transcript_anno" );
my $newt_head = $excel_newt->add_format( fg_color => 0x30, align => 'center', bold => 1);
$sheet_newt->write( 0, 0, "Transcript_ID", $newt_head );
$sheet_newt->set_column( 'A:A', 18 );
$sheet_newt->write( 0, 1, "Length", $newt_head );
$sheet_newt->set_column( 'B:B', 12 );
$sheet_newt->write( 0, 2 , "Best_Hit_to_NT_ID", $newt_head );
$sheet_newt->set_column( "C:C", 40 );
$sheet_newt->write( 0, 3 , "Best_Hit_to_SwissProt_ID", $newt_head );
$sheet_newt->set_column( "D:D", 30 );
$sheet_newt->write( 0, 4 , "Best_Hit_to_NT_Evalue", $newt_head );
$sheet_newt->set_column( "E:E", 10 );
$sheet_newt->write( 0, 5 , "Best_Hit_to_SwissProt_Evalue", $newt_head );
$sheet_newt->set_column( "F:F", 10 );
$sheet_newt->write( 0, 6 , "Best_Hit_to_NT_Desc", $newt_head );
$sheet_newt->set_column( "G:G", 60 );
$sheet_newt->write( 0, 7 , "Best_Hit_to_SwissProt_Desc", $newt_head );
$sheet_newt->set_column( "H:H", 60 );
$sheet_newt->write( 0, 8 , "GO_from_GI", $newt_head );
$sheet_newt->set_column( "I:I", 60 );

my $line_anno = 1;
open (LEN, ">/dev/shm/trans_length.matrix");
foreach my $query (keys %transcriptome) {
    my $q_len = $query;
    my $query1 = $query;
    $q_len =~ s/.+Length_//;
    $query1 =~ s/_Length_\d+//;
    print LEN $q_len,"\n";
    $sheet_newt->write($line_anno, 0, $query1,);
    $sheet_newt->write($line_anno, 1, $q_len);
    $sheet_newt->write ($line_anno,  2, $transcriptome{$query}{'nt_id'});
    $sheet_newt->write ($line_anno,  3, $transcriptome{$query}{'sw_id'});
    $sheet_newt->write ($line_anno,  4, $transcriptome{$query}{'nt_ev'});
    $sheet_newt->write ($line_anno,  5, $transcriptome{$query}{'sw_ev'});
    $sheet_newt->write ($line_anno,  6, $transcriptome{$query}{'nt_desc'});
    $sheet_newt->write ($line_anno,  7, $transcriptome{$query}{'sw_desc'});
    $sheet_newt->write ($line_anno,  8, $transcriptome{$query}{'go'});
    $line_anno++;
}
system ("Rscript ~/workdir/my_script/trans_length.R");
