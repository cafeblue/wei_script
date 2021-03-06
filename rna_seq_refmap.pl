#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use warnings;

use Getopt::Long;
#use PerlIO::gzip;
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
# q1=./sample1.fq
# READSLENG=36
#
# [lib_se]
# q1=./sample2.fq
#
# [lib_pe]
# q1=./sample3_read1.fq
# q2=./sample3_read2.fq
# INSERTSIZE=400
# MISMATCH=5
#
# [lib_pe]
# q1=./sample4_read1.fq
# q2=./sample4_read2.fq
# INSERTSIZE=380
# MISMATCH=5
#
# [map]
# REF=/home/wangw/workdir/genome/bowtie/hg19.fa
#
# [express]
# GTF=/home/wangw/workdir/R1_t-t9/refGene_my.gtf
#
# [predict_new_transcript]
# ## replace yes with no, will not predict. default no.
# PNT=yes         
#
# [predict_gene_fusion]
# ## replace yes with no, will not run. default no.
# ## please specify the files to be used to predict Gene Fusion.
# ## and specify the absolute path of the file!!!!!!
# PGF=yes
# GFL="/home/wangw/workdir/BFC2011142/sample3_read1.fq /home/wangw/workdir/BFC2011142/sample3_read2.fq"
# GFL="/home/wangw/workdir/BFC2011142/sample3_single_read.fq"
#
# [compare_pair]
# PAIR=sample3_to_sample4
# PAIR=sample1_to_sample2
# PAIR=sample1_to_sample3
# PAIR=sample4_to_sample4
#
# [heat_map]
# ## replace yes with no, will not run. default no.
# HEM=no
#
# [species]
# SPECIES=ATH
#
# [database]
# DB_NT=/share/data/database/NT/nt 
# DB_SW=/share/data/database/Uniprot/uniprot_sprot.fasta
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
my @insertsize = ();
my $ref;
my $gtf;
my $pnt = "no";
my $hem = "no";
my $pgf = "no";
my @pgf;
my $spe = "NNN";
my $db_nt = "/share/data/database/NT/nt";
my $db_sw = "/share/data/database/Uniprot/uniprot_sprot.fasta";
my %pair_id_list;
my $se36="no";

while (<CONF>) {
    chomp;
    if (/^q1\=(.+)/) {
        push @seq_files, $1;
    }
    elsif (/^q2\=(.+)/) {
        push @seq_files2, $1;
    }
    elsif (/^REF\=(.+)/) {
        $ref = $1;
    }
    elsif (/^GTF\=(.+)/) {
        $gtf = $1;
    }
    elsif (/^INSERTSIZE=(.+)/) {
        push @insertsize, $1;
    }
    elsif (/^PAIR=(.+)/) {
        $pair_id_list{$1} = 1;
    }
    elsif (/^PNT=(\w+)/) {
        if ($1 =~ /yes/i) {
            $pnt = "yes";
        }
        elsif ($1 =~ /no/i) {
             $pnt = "no";
        }
        else {
            die "Parameter PNT is unrecognizable... \n";
        }
    }
    elsif (/^HEM=(\w+)/) {
        if ($1 =~ /yes/i) {
            $hem = "yes";
        }
        elsif ($1 =~ /no/i) {
             $hem = "no";
        }
        else {
            die "Parameter HEM is unrecognizable... \n";
        }
    }
    elsif (/^PGF=(\w+)/) {
        if ($1 =~ /yes/i) {
            $pgf = "yes";
            my $tmp_conf_line = <CONF>;
            if ($tmp_conf_line =~ /GFL=\"(.+)\"/) {
                push @pgf, $1;
                $tmp_conf_line = <CONF>;
            }
            else {
                die "Parameter PNT is unrecognizable... \n";
            }
            while (1) {
                if ($tmp_conf_line =~ /GFL=\"(.+)\"/) {
                    push @pgf, $1;
                    $tmp_conf_line = <CONF>;
                }
                else {
                    last;
                }
            }
            
        }
        elsif ($1 =~ /no/i) {
             $pgf = "no";
        }
        else {
            die "Parameter PNT is unrecognizable... \n";
        }
    }
    elsif (/^SPECIES=([A-Z]{3})/) {
        $spe = $1;
    }
    elsif (/^DB_NT=(.+)/) {
        $db_nt = $1;
    }
    elsif (/^DB_SW=(.+)/) {
        $db_sw = $1;
    }
    elsif (/READSLENG=36/) {
        $se36 = "yes";
    }
}

open (RRPKM, ">rpkm.matrix");
open (BP, ">bp.matrix");
open (CC, ">cc.matrix");
open (MF, ">mf.matrix");

#  if only one sample, comparison is useless.
if ($#seq_files == 0) {
    single_input();
}
else {
    multiple_input();
}

if ($pgf eq "yes") {
    foreach (@pgf) {
        gene_fusion_dection($_);
    }
}

sub gene_fusion_dection {
    my @files = split(/\s/, $_[0]);
    if ($#files == 1) {
        my $config_file = $files[0];
        $config_file =~ s/.+\///;
        my $dir = $config_file;
        $dir =~ s/\..+//;
        $config_file =~ s/\..+/_FMconfig.txt/;
        open (FM_CONF, ">$config_file") or die $!;
        print FM_CONF "<Files>\n";
        print FM_CONF "$files[0]\n";
        print FM_CONF "$files[1]\n";
        print FM_CONF "\n";
        print FM_CONF "<Options>\n";
        print FM_CONF "PairedEnd=True\nRnaMode=True\nUse32BitMode=False\nThreadNumber=16\nFileFormat=FASTQ\n";
        print FM_CONF "MinimalFusionAlignmentLength=25\nFusionReportCutoff=1\nNonCanonicalSpliceJunctionPenalty=4\n";
        print FM_CONF "MinimalHit=2\nMinimalRescuedReadNumber=1\nOutputFusionReads=True\nFilterBy=DefaultList\n\n";
        print FM_CONF "<Output>\nTempPath=/tmp/FusionMapTemp\n";
        print FM_CONF "OutputPath=/home/wangw/newworkdir/fusionmap_test/$dir\n";
        print FM_CONF "OutputName=$dir\n";
        close(FM_CONF);
        system ("mono-sgen /home/wangw/newworkdir/FusionMap_2012-01-01/bin/FusionMap.exe --semap /home/wangw/newworkdir/FusionMap_2012-01-01 Human.B37 RefGene $config_file > $config_file.log 2>$config_file.err");
        system ("cp /home/wangw/newworkdir/fusionmap_test/$dir/$dir.FusionReport.txt .");
        open (FM_REPO, "$dir.FusionReport.txt") or die $!;
        open (FM_REPO_O, ">$dir.FusionReport_filter.txt") or die $!;
        while (my $fm_repo = <FM_REPO>) {
            if ($. == 1) {
                print FM_REPO_O $fm_repo;
            }
            else {
                my ($uniq_reads, $seed_reads) = (split(/\t/, $fm_repo))[1,2];
                if ($uniq_reads >= 10 && $seed_reads >= 5) {
                    print FM_REPO_O $fm_repo;
                }
            }
        }
        close(FM_REPO);
        close(FM_REPO_O);
    }
    elsif ($#files == 0) {
        my $config_file = $files[0];
        $config_file =~ s/.+\///;
        my $dir = $config_file;
        $dir =~ s/\..+//;
        $config_file =~ s/\..+/_FMconfig.txt/;
        open (FM_CONF, ">$config_file") or die $!;
        print FM_CONF "<Files>\n";
        print FM_CONF "$files[0]\n";
        print FM_CONF "$files[1]\n";
        print FM_CONF "\n";
        print FM_CONF "<Options>\n";
        print FM_CONF "PairedEnd=False\nRnaMode=True\nUse32BitMode=False\nThreadNumber=16\nFileFormat=FASTQ\n";
        print FM_CONF "MinimalFusionAlignmentLength=25\nFusionReportCutoff=1\nNonCanonicalSpliceJunctionPenalty=4\n";
        print FM_CONF "MinimalHit=2\nMinimalRescuedReadNumber=1\nOutputFusionReads=True\nFilterBy=DefaultList\n\n";
        print FM_CONF "<Output>\nTempPath=/tmp/FusionMapTemp\n";
        print FM_CONF "OutputPath=/home/wangw/newworkdir/fusionmap_test/$dir\n";
        print FM_CONF "OutputName=$dir\n";
        close(FM_CONF);
        system ("mono-sgen /home/wangw/newworkdir/FusionMap_2012-01-01/bin/FusionMap.exe --semap /home/wangw/newworkdir/FusionMap_2012-01-01 Human.B37 RefGene $config_file > $config_file.log 2>$config_file.err");
        system ("cp /home/wangw/newworkdir/fusionmap_test/$dir/$dir.FusionReport.txt .");
        open (FM_REPO, "$dir.FusionReport.txt") or die $!;
        open (FM_REPO_O, ">$dir.FusionReport_filter.txt") or die $!;
        while (my $fm_repo = <FM_REPO>) {
            if ($. == 1) {
                print FM_REPO_O $fm_repo;
            }
            else {
                my ($uniq_reads, $seed_reads) = (split(/\t/, $fm_repo))[1,2];
                if ($uniq_reads >= 10 && $seed_reads >= 5) {
                    print FM_REPO_O $fm_repo;
                }
            }
        }
        close(FM_REPO);
        close(FM_REPO_O);
    }
    else {
        die "GFL Parameter is wrong! two files for PE run and only one file for SE run!\n";
    }
}

sub single_input {
#if ($#seq_files == 0) {
    my $seq_name = pop(@seq_files);
    my $seq = $seq_name;
    $seq =~ s/\..+//;
    $seq =~ s/ //g;
    $seq =~ s/_R1//g;
    $seq =~ s/_read1//g;
    print BP "Description\t$seq\n";
    print CC "Description\t$seq\n";
    print MF "Description\t$seq\n";
    my $seq_name2;
    my $ins;

    # if lib is a PE lib, parameters for tophat and cufflinks are different.
    if ($#insertsize > -1) {
        $seq_name2 = pop(@seq_files2);
        $ins = pop(@insertsize);
        system("tophat -o tophat_$seq  -r $ins --solexa-quals -p 16 -G $gtf $ref $seq_name $seq_name2");
        system("nohup random_eva.pl $seq_name tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
        system("nohup saturation_eva.pl $seq_name tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
        system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -G $gtf ./tophat_$seq/accepted_hits.bam");
    }
    else {
        if ($se36 eq "yes") {
            system("tophat -o tophat_$seq --solexa-quals -p 16 --no-gtf-juncs --no-novel-juncs -G $gtf $ref $seq_name");
        }
        else {
            system("tophat -o tophat_$seq --solexa-quals -p 16 -G $gtf $ref $seq_name");
        }
        system("nohup random_eva.pl $seq_name tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
        system("nohup saturation_eva.pl $seq_name tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
        system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -G $gtf ./tophat_$seq/accepted_hits.bam");
    }

    # valuable store the final data in the rpkm_table.xlsx, GO information is included.
    my %all_go;

    # valuable sotre the number of rpkm value in different range. they are 0, 0-10, 10-20, ... 90-100, large than 100, totally 12 number.
    my @rpkm = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    # files for output
    my $excel = Excel::Writer::XLSX -> new ( "RPKM_table.xlsx" );
    my $excel_dist = Excel::Writer::XLSX -> new ( "RPKM_Chart.xlsx" );
    my $excel_gote = Excel::Writer::XLSX -> new ( "GO_Chart.xlsx" );
    my $sheet_anno = $excel->add_worksheet( "RPKM" );
    my $sheet_summ = $excel_dist->add_worksheet( "Summary" );
    my $sheet_gote = $excel_gote->add_worksheet( "Gene_Ontology" );
    my $my_head = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge = $excel->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format = $excel->add_format( fg_color => 0x2C, align => 'center');
    my $my_head_rpkm = $excel_dist->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_rpkm = $excel_dist->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_rpkm = $excel_dist->add_format( fg_color => 0x2C, align => 'center');
    my $my_head_go = $excel_gote->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_go = $excel_gote->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_go = $excel_gote->add_format( fg_color => 0x2C, align => 'center');
    my $num_format = $excel_dist->add_format( num_format => '###.00%' );

    # format the output file
    $sheet_anno->write( 0, 0, "Chromosome", $my_head );
    $sheet_anno->set_column( 'A:A', 12 );
    $sheet_anno->set_column( 'B:B', 12 );
    $sheet_anno->set_column( 'C:C', 15 );
    $sheet_anno->set_column( 'D:D', 10 );
    $sheet_anno->set_column( 'E:E', 10 );
    $sheet_anno->set_column( 'F:F', 6 );
    $sheet_anno->set_column( 'G:G', 30 );
    $sheet_anno->set_column( 'H:H', 50 );
    $sheet_anno->set_column( 'I:I', 50 );
    $sheet_anno->write( 0, 1, "Gene_Name", $my_head );
    $sheet_anno->write( 0, 2, "Accession_Num", $my_head );
    $sheet_anno->write( 0, 3, "GI", $my_head );
    $sheet_anno->write( 0, 4, "Exon_Length", $my_head );
    $sheet_anno->write( 0, 5, "RPKM", $my_head );
    $sheet_anno->write( 0, 6, "KEGG_Pathway", $my_head );
    $sheet_anno->write( 0, 7, "Description", $my_head );
    $sheet_anno->write( 0, 8, "Gene_Ontology", $my_head );
    my $line_anno = 0;

    $sheet_summ->write( 0, 0, "RPKM Destribution", $my_merge_rpkm );
    $sheet_summ->set_column( 'A:A', 20 );
    $sheet_summ->set_column( 'B:B', 10 );
    $sheet_summ->set_column( 'C:C', 10 );
    $sheet_summ->write_blank( 0, 1,  $my_merge_rpkm );
    $sheet_summ->write_blank( 0, 2,  $my_merge_rpkm );
    $sheet_summ->write( 1, 0, "Range", $my_head_rpkm );
    $sheet_summ->write( 1, 1, "Number", $my_head_rpkm );
    $sheet_summ->write( 1, 2, "Ratio", $my_head_rpkm );

    $sheet_gote->write( 0, 0, "GO Ontology", $my_merge_go);
    $sheet_gote->set_column( 'A:A', 20 );
    $sheet_gote->set_column( 'B:B', 50 );
    $sheet_gote->set_column( 'C:C', 16 );
    $sheet_gote->write_blank( 0, 1,  $my_merge_go );
    $sheet_gote->write_blank( 0, 2,  $my_merge_go );
    $sheet_gote->write_blank( 0, 3,  $my_merge_go );
    $sheet_gote->write_blank( 0, 4,  $my_merge_go );
    $sheet_gote->write( 1, 0, "Type", $my_head_go );
    $sheet_gote->write( 1, 1, "Description", $my_head_go );
    $sheet_gote->write( 1, 2, "Gene Number", $my_head_go );
    my $line_summ = 1;

    open (RPKM, "./cufflinks_$seq/isoforms.fpkm_tracking") or die $!;
    my $total_lines = `wc -l ./cuffdiff_all/isoform_exp.diff`;
    chomp($total_lines);
    $total_lines =~ s/\s.+//;
    my $line = <RPKM>;
    my $dbh = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";

    # parse the output file of cufflinks, extract the accession_number, rpkm, q-value.
    while (<RPKM>) {
        $line_anno++;
        my @lines = split(/\t/, $_);

        # get gi according to the accession_number, then get the description, finally get the GO id .
        my $sth = $dbh->prepare("SELECT gi FROM gene_annotation.gi2accession WHERE accession = \'$lines[0]\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        my $gi = pop(@row);
        $sth = $dbh->prepare("SELECT description FROM gene_annotation.nt_desc WHERE gi = \'$gi\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        my $desc = pop(@row);
        $sth = $dbh->prepare("SELECT goid FROM gene_annotation.gi2go WHERE gi = \'$gi\'");
        $sth->execute();
        @row = ();
        my $rows_ref = $sth->fetchall_arrayref ;

        # put all the GO id of a gene into an array.
        while (my $row = pop(@$rows_ref)) {
            push @row, @$row;
        }

        # get the levle 2 description from the mysql database according to the GO id array.
        foreach my $go_id (@row) {
            $sth = $dbh->prepare("select term_type,description from gene_annotation.level2desc where go = \'$go_id\'");
            $sth->execute();
            my $rows_ref = $sth->fetchall_arrayref;
            while (my $row = pop(@$rows_ref)) {
                if (exists $all_go{${$row}[0]}{${$row}[1]}) {
                    $all_go{${$row}[0]}{${$row}[1]}++;
                }
                else {
                    $all_go{${$row}[0]}{${$row}[1]} = 1;
                }
            }

        }

        # join all the GO id together for print.
        my $go_desc = join('; ', @row);

        # print the information into the RPKM_table.xlsx
        $sheet_anno->write ( $line_anno, 0, "$lines[6]" , $my_format);
        $sheet_anno->write ( $line_anno, 1, "$lines[4]" , $my_format);
        $sheet_anno->write ( $line_anno, 2, "$lines[0]" , $my_format);
        $sheet_anno->write ( $line_anno, 3, "\=HYPERLINK\(\"http\:\/\/www\.ncbi\.nlm\.nih\.gov\/nuccore\/$gi\",\"$gi\"\)", $my_format);
        $sheet_anno->write ( $line_anno, 4, "$lines[7]" , $my_format);
        $sheet_anno->write ( $line_anno, 5, "$lines[10]" , $my_format);
        $sth = $dbh->prepare("SELECT pathway FROM kegg_pathway.species_genename_pathway WHERE gene_name = \'$lines[4]\' and species = \'$spe\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        my $pathway = pop(@row);
        $sheet_anno->write ( $line_anno, 6, "$pathway" , $my_format);
        $sheet_anno->write ( $line_anno, 7, "$desc" , $my_format);
        $sheet_anno->write ( $line_anno, 8, "$go_desc" , $my_format);

        # count the distribution of the RPKM value.
        if ($lines[10] == 0) {
            $rpkm[0]++;
        }
        elsif ($lines[10] <= 10) {
            $rpkm[1]++;
        }
        elsif ($lines[10] <= 20) {
            $rpkm[2]++;
        }
        elsif ($lines[10] <= 30) {
            $rpkm[3]++;
        }
        elsif ($lines[10] <= 40) {
            $rpkm[4]++;
        }
        elsif ($lines[10] <= 50) {
            $rpkm[5]++;
        }
        elsif ($lines[10] <= 60) {
            $rpkm[6]++;
        }
        elsif ($lines[10] <= 70) {
            $rpkm[7]++;
        }
        elsif ($lines[10] <= 80) {
            $rpkm[8]++;
        }
        elsif ($lines[10] <= 90) {
            $rpkm[9]++;
        }
        elsif ($lines[10] <= 100) {
            $rpkm[10]++;
        }
        else {
            $rpkm[11]++;
        }

        # print the status of the working....
#        print "$. of $total_lines ...  ";
#        my $percent = sprintf('%5.2f', $./$total_lines);
#        print $percent,'%', "\cM";
    }

    # write the GO chart file.
    $line_summ++;
    foreach my $level1 (keys %all_go) {
        $sheet_gote->write($line_summ, 0, $level1, $my_format_go );
        foreach my $level2 (keys %{$all_go{$level1}}) {
            $sheet_gote->write($line_summ, 1, $level2, $my_format_go );;
            $sheet_gote->write($line_summ, 2, $all_go{$level1}{$level2}, $my_format_go );
            if ($level1 eq "molecular_function") {
                print MF "$level2\t$all_go{$level1}{$level2}\n";
            }
            elsif ($level1 eq "cellular_component") {
                print CC "$level2\t$all_go{$level1}{$level2}\n";
            }
            elsif ($level1 eq "biological_process") {
                print BP "$level2\t$all_go{$level1}{$level2}\n";
            }
            else {
                die "level1 of GO err!\n";
            }
            $line_summ++;
        }
    }
    close(BP);
    close(CC);
    close(MF);
    system("Rscript ~/workdir/my_script/go.R bp.matrix cc.matrix mf.matrix GO_Plot.pdf");

    # write the discription of RPKM file.
    my $lines_of_gote = $line_summ--;
    $lines_of_gote--;
    $line_summ = 1;
    foreach my $rpkm_val (shift(@rpkm)) {
        $line_summ++;
        if ($line_summ == 2) {
            $sheet_summ->write( $line_summ, 0, "0", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            print RRPKM "$rpkm_val\n";
            $sheet_summ->write( $line_summ, 2, '=B3/B15', $num_format );
        }
        elsif ($line_summ <= 12) {
            my $range = ($line_summ - 2) * 10;
            my $range1 = $range - 10;
            my $line_id = $line_summ + 1;
            $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            print RRPKM "$rpkm_val\n";
            $sheet_summ->write( $line_summ, 2, "=B$line_id/B15", $num_format );
        }
        elsif ($line_summ == 13) {
            $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            print RRPKM "$rpkm_val\n";
            $sheet_summ->write( $line_summ, 2, "=B14/B15", $num_format);
        }
        else {
            die "Something Wrong\?\n";
        }
    }
    close(RRPKM);
    system("Rscript ~/workdir/my_script/rpkm.R rpkm.matrix RPKM_Distribution.pdf");
    $sheet_summ->write( 14, 0, "Total:", $my_format_rpkm );
    $sheet_summ->write( 14, 1, "=SUM(B3:B14)" );
    $sheet_summ->write( 14, 2, "=SUM(C3:C14)", $num_format);
    my $chart = $excel_dist->add_chart( type => 'column', embedded => 1 );
    
    $chart->add_series(
        name       => "$seq",
        categories => '=Summary!$A$3:$A$14',
        values     => '=Summary!$B$3:$B$14',
    );
    
    $chart->set_title ( name => 'RPKM Distribution' );
    $chart->set_y_axis( name => 'Number' );
    $chart->set_x_axis( name => 'RPKM Range' );
    
    # Set an Excel chart style. Blue colors with white outline and shadow.
    $chart->set_style( 21 );
    
    # Insert the chart into the worksheet (with an offset).
    $sheet_summ->insert_chart( 'A16', $chart, 0, 0, 2, 2 ); 

    my $chart_go = $excel_gote->add_chart( type => 'column', embedded => 1 );
    $chart_go->add_series(
        name       => "$seq",
        categories => "=Gene_Ontology!\$A\$3:\$B\$$lines_of_gote",
        values     => "=Gene_Ontology!\$C\$3:\$C\$$lines_of_gote",
    );
    $lines_of_gote++;
    $lines_of_gote++;
    $chart_go->set_title ( name => 'GO Distribution' );
    $chart_go->set_x_axis( name => "Catalogue" );
    $chart_go->set_y_axis( name => 'Number' );
    $chart_go->set_style( 21 );
    $sheet_gote->insert_chart( "A$lines_of_gote", $chart_go, 0, 0, 2.5, 3 ); 
}

sub multiple_input {
#else {
    open (VENN, ">venn.matrix");
    print VENN "ID";
    my $all_bamfiles = "";
    my $all_gtffiles = "";
    my %transcriptome;
    my %rpkm;
    my %all_go;
    my %isoform_list;
    my $p_sample = 0;
    my %samples;
    print BP "Description";
    print CC "Description";
    print MF "Description";
    for (my $i = 0 ; $i <= $#seq_files; $i++) {
        $p_sample++;
        my $id = "q".$p_sample;
        my $seq = $seq_files[$i];
        $seq =~ s/\..+//;
        $seq =~ s/ //g;
        $seq =~ s/_R1//g;
        $seq =~ s/_read1//g;
        $samples{$id} = $seq;
        print BP "\t$seq";
        print CC "\t$seq";
        print MF "\t$seq";
        print VENN "\t$seq";
        if ($pnt eq "yes") {   
            if ($#insertsize > -1) {
                system("tophat -o tophat_$seq -r $insertsize[$i] --solexa-quals -p 16 -G $gtf $ref $seq_files[$i] $seq_files2[$i]");
                system("nohup random_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
                system("nohup saturation_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
                system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -g $gtf ./tophat_$seq/accepted_hits.bam");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
                $all_gtffiles .= "cufflinks_$seq/transcripts.gtf\n";
            }
            else {
                if ($se36 eq "yes") {
                    system("tophat -o tophat_$seq --solexa-quals -p 16 --no-gtf-juncs --no-novel-juncs -G $gtf $ref $seq_files[$i]");
                }
                else {
                    system("tophat -o tophat_$seq --solexa-quals -p 16 -G $gtf $ref $seq_files[$i]");
                }
                system("nohup random_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
                system("nohup saturation_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
                system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -g $gtf ./tophat_$seq/accepted_hits.bam");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
                $all_gtffiles .= "cufflinks_$seq/transcripts.gtf\n";
            }
        }
        else {
            if ($#insertsize > -1) {
                system("tophat -o tophat_$seq -r $insertsize[$i] --solexa-quals -p 16 -G $gtf $ref $seq_files[$i] $seq_files2[$i]");
                system("nohup random_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
                system("nohup saturation_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
            }
            else {
                if ($se36 eq "yes") {
                    system("tophat -o tophat_$seq --solexa-quals -p 16 --no-gtf-juncs --no-novel-juncs -G $gtf $ref $seq_files[$i]");
                }
                else {
                    system("tophat -o tophat_$seq --solexa-quals -p 16 -G $gtf $ref $seq_files[$i]");
                }
                system("nohup random_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $ref $gtf 1>$seq.random.log 2>$seq.random.err &");
                system("nohup saturation_eva.pl $seq_files[$i] tophat_$seq/accepted_hits.bam $gtf 1>$seq.saturation.log 2>$seq.saturation.err &");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
            }
        }
    }
    print VENN "\n";
    print BP "\n";
    print CC "\n";
    print MF "\n";

    my %old_id;
    my %merged_gtf;
    my %merged_cov;
    if ($pnt eq "yes") {
        open (GTF_LST, ">gtf_lst.txt") or die $!;
        print GTF_LST $all_gtffiles;
        close(GTF_LST);
        system("cuffmerge -o cuffmerge_all -g $gtf -s $ref.fa -p 16 gtf_lst.txt");
        system("cuffdiff --no-update-check -p 16 -o cuffdiff_all ./cuffmerge_all/merged.gtf $all_bamfiles");
    
        open (GTF_REL, "./cuffmerge_all/merged.gtf") or die $!;
        while (<GTF_REL>) {
            my ($trans_id, $old_trans1, $old_trans2) = (split(/;/, $_))[1,4,5];
            $trans_id =~ s/ //g;
            $trans_id =~ s/transcript_id//;
            $trans_id =~ s/"//g;
            if (exists $merged_gtf{$trans_id}) {
                $merged_gtf{$trans_id} .= $_;
            }
            else {
                $merged_gtf{$trans_id} = $_;
            }

            if ($old_trans1 =~ /nearest_ref/) {
                $old_trans1 =~ s/ //g;
                $old_trans1 =~ s/nearest_ref//;
                $old_trans1 =~ s/"//g;
                $old_id{$trans_id} = $old_trans1;
            }
            elsif ($old_trans2 =~ /nearest_ref/)  {
                $old_trans2 =~ s/ //g;
                $old_trans2 =~ s/nearest_ref//;
                $old_trans2 =~ s/"//g;
                $old_id{$trans_id} = $old_trans2;
            }
            else {
                if (/oId "(.+?)"/) {
                    $old_id{$trans_id} = $1;
                }
                else {
                    die "\t$old_trans1\t$old_trans2\tline $.\toId not found!\n\tplease check the columns of merged.gtf file\n";
                }
            }
        }

#        foreach ( split(/\n/, $all_gtffiles) ) {
#            open (GTF_COV, "$_") or die $!;
            open (GTF_COV, "./cuffmerge_all/transcripts.gtf") or die $!;
            while (<GTF_COV>) {
                if (/transcript.+transcript_id "(.+?)".+cov "(.+?)"/) {
                    $merged_cov{$1} = $2;
                }
            }
            close (GTF_COV);
#        }
    }
    else {
        system("cuffdiff --no-update-check -p 16 -o cuffdiff_all $gtf $all_bamfiles");
    }

    my $excel = Excel::Writer::XLSX -> new ( "RPKM_table.xlsx" );
    my $excel_dist = Excel::Writer::XLSX -> new ( "RPKM_Chart.xlsx" );
    my $excel_gote = Excel::Writer::XLSX -> new ( "GO_Chart.xlsx" );
    my $excel_diff = Excel::Writer::XLSX -> new ( "Diff_Express_Gene_table.xlsx" );
    my $excel_godi = Excel::Writer::XLSX -> new ( "Diff_Express_Gene_GO_Chart.xlsx" );
    my $sheet_anno = $excel->add_worksheet( "RPKM" );
    my $sheet_summ = $excel_dist->add_worksheet( "Summary" );
    my $sheet_gote = $excel_gote->add_worksheet( "Gene_Ontology" );
    my $my_head = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge = $excel->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format = $excel->add_format( fg_color => 0x2C, align => 'center');
    my $my_head_rpkm = $excel_dist->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_rpkm = $excel_dist->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_rpkm = $excel_dist->add_format( fg_color => 0x2C, align => 'center');
    my $my_head_go = $excel_gote->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_go = $excel_gote->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_go = $excel_gote->add_format( fg_color => 0x2C, align => 'center');
    my $num_format = $excel_dist->add_format( num_format => '###.00%' );

    $sheet_gote->write( 0, 0, "GO Ontology", $my_merge_go);
    $sheet_gote->set_column( 'A:A', 20 );
    $sheet_gote->set_column( 'B:B', 50 );
    $sheet_gote->set_column( 'C:C', 16 );
    $sheet_gote->set_column( 'D:D', 16 );
    $sheet_gote->set_column( 'E:E', 16 );
    $sheet_gote->set_column( 'F:F', 16 );
    $sheet_gote->set_column( 'G:G', 16 );
    $sheet_gote->set_column( 'H:H', 16 );
    $sheet_gote->write_blank( 0, 1,  $my_merge_go );
    $sheet_gote->write_blank( 0, 2,  $my_merge_go );
    $sheet_gote->write( 1, 0, "Type", $my_head_go);
    $sheet_gote->write( 1, 1, "Description", $my_head_go );
    my $line_summ = 1;
###  select name from gene_annotation.term where id in (select term1_id from (select (B.distance - 2) as DIST, A.id from (select id from gene_annotation.term where acc = 'GO:0002790') A, gene_annotation.graph_path B where B.term2_id = A.id  and B.term1_id = '34658') A, gene_annotation.graph_path B where B.term2_id = A.id and B.distance = A.DIST ) and id in (select term2_id from gene_annotation.graph_path where term1_id = '34658' and distance = '2' and relation_distance = '2');
    open (RPKM, "./cuffdiff_all/isoform_exp.diff") or die $!;
    my $total_lines = `wc -l ./cuffdiff_all/isoform_exp.diff`;
    chomp($total_lines);
    $total_lines =~ s/\s.+//;
    my $line = <RPKM>;
    my $dbh = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";

    while (<RPKM>) {
        my @lines = split(/\t/, $_);
        if ($lines[7] == 0 && $lines[8] == 0) {
            next;
        }

        if ($pnt eq "yes") {
            if ($old_id{$lines[0]} =~ /CUFF.*/) {
#                print $old_id{$lines[0]},"\t",$merged_cov{$old_id{$lines[0]}},"\n";
                if ($merged_cov{$old_id{$lines[0]}} >= 1) {
                    $transcriptome{$lines[0]}{'chr'} = $lines[3];
                    $transcriptome{$lines[0]}{'gene_name'} = $lines[2];
                    $transcriptome{"$lines[0]"}{$samples{$lines[4]}} = $lines[7];
                    $transcriptome{"$lines[0]"}{$samples{$lines[5]}} = $lines[8];
                    my $pair_id = $samples{$lines[4]}."_to_".$samples{$lines[5]};
                    $transcriptome{"$lines[0]"}{$pair_id} = $lines[12];
#                    if (not exists $pair_id_list{$pair_id}) {
#                        $pair_id_list{$pair_id} = 1;
#                    }
                }
                next;
            }
            else {
               $lines[0] = $old_id{$lines[0]};
            }
        }

        my $sth = $dbh->prepare("SELECT gi FROM gene_annotation.gi2accession WHERE accession = \'$lines[0]\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        my $gi = pop(@row);
        if (not $gi) {
#            warn "gi of $lines[0] does not exists\n";
            next;
        }
        $sth = $dbh->prepare("SELECT description FROM gene_annotation.gi2description WHERE gi = \'$gi\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        my $desc = pop(@row);
        $sth = $dbh->prepare("SELECT goid FROM gene_annotation.gi2go WHERE gi = \'$gi\'");
        $sth->execute();
        @row =  ();
        my $rows_ref = $sth->fetchall_arrayref ;
        while (my $row = pop(@$rows_ref)) {
            @row = (@row, @$row);
        }

        if ($lines[7] != 0 && not exists $isoform_list{"$lines[0]"}{$samples{$lines[4]}}) {
            foreach my $go_id (@row) {
                $sth = $dbh->prepare("select term_type,description from gene_annotation.level2desc where go = \'$go_id\'");
                $sth->execute();
                $rows_ref = $sth->fetchall_arrayref;
                while (my $row = pop(@$rows_ref)) {
                    if (exists $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[4]}}) {
                        $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[4]}} ++;
                    }
                    else {
                        $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[4]}} = 1;
                    }
                }
            }
        }
        if ($lines[8] != 0 && not exists $isoform_list{"$lines[0]"}{$samples{$lines[5]}}) {
            foreach my $go_id (@row) {
                $sth = $dbh->prepare("select term_type,description from gene_annotation.level2desc where go = \'$go_id\'");
                $sth->execute();
                $rows_ref = $sth->fetchall_arrayref;
                while (my $row = pop(@$rows_ref)) {
                    if (exists $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[5]}}) {
                        $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[5]}} ++;
                    }
                    else {
                        $all_go{${$row}[0]}{${$row}[1]}{$samples{$lines[5]}} = 1;
                    }
                }
            }
        }
        $isoform_list{"$lines[0]"}{'go_desc'} = join('; ', @row);
        $isoform_list{"$lines[0]"}{'gene_name'} = $lines[2];
        $isoform_list{"$lines[0]"}{'chr'} = $lines[3];
        $isoform_list{"$lines[0]"}{'acc'} = $lines[0];
        $isoform_list{"$lines[0]"}{$samples{$lines[4]}} = $lines[7];
        $isoform_list{"$lines[0]"}{$samples{$lines[5]}} = $lines[8];
        my $pair_id = $samples{$lines[4]}."_to_".$samples{$lines[5]};
        $isoform_list{"$lines[0]"}{$pair_id} = $lines[12];
#        if (not exists $pair_id_list{$pair_id}) {
#            $pair_id_list{$pair_id} = 1;
#        }
        $isoform_list{"$lines[0]"}{'gi'} = "\=HYPERLINK\(\"http\:\/\/www\.ncbi\.nlm\.nih\.gov\/nuccore\/$gi\",\"$gi\"\)";
        $isoform_list{"$lines[0]"}{'desc'} = $desc;
#        print "$.\tof $total_lines ...  \t", sprintf ('%5.2f', $./$total_lines*100), "%\cM";
    }

    my $columns_of_gote = "F";
    $sheet_anno->write( 0, 0, "Chromosome", $my_head );
    $sheet_anno->write( 0, 1, "Gene_Name", $my_head );
    $sheet_anno->set_column( 'A:A', 16 );
    $sheet_anno->set_column( 'B:B', 16 );
    $sheet_anno->set_column( 'C:C', 15 );
    $sheet_anno->set_column( 'D:D', 10 );
    $sheet_anno->set_column( 'E:E', 15 );
    $sheet_anno->write( 0, 2, "Accession_Num", $my_head );
    $sheet_anno->write( 0, 3, "GI", $my_head );
    for (my $i = 0 ; $i <= $#seq_files; $i++) {
        my $seq = $seq_files[$i];
        $seq =~ s/\..+//;
        $seq =~ s/ //g;
        $seq =~ s/_R1//g;
        $seq =~ s/_read1//g;
        $sheet_anno->write( 0, 4+$i, "RPKM_$seq", $my_head );
        $sheet_anno->set_column( "$columns_of_gote:$columns_of_gote", 15 );
#        $sheet_diff->write( 0, 4+$i, "RPKM_$seq", $my_head_diff );
#        $sheet_diff->set_column( "$columns_of_gote:$columns_of_gote", 15 );
        $columns_of_gote++;
    }

    my $pair_count = 0;
    foreach (keys %pair_id_list) {
        $sheet_anno->write( 0, 5+$#seq_files+$pair_count, "q-Value_$_", $my_head );
        $sheet_anno->set_column( "$columns_of_gote:$columns_of_gote", 25 );
#        $sheet_diff->write( 0, 5+$#seq_files+$pair_count, "q_Value_$_", $my_head_diff );
#        $sheet_diff->set_column( "$columns_of_gote:$columns_of_gote", 25 );
        $columns_of_gote++;
        $pair_count++;
    }
    $sheet_anno->write( 0, 5+$#seq_files+$pair_count, "KEGG_Pathway", $my_head );
    $sheet_anno->write( 0, 6 + $#seq_files + $pair_count, "Description", $my_head );
    $sheet_anno->set_column( "$columns_of_gote:$columns_of_gote", 30 );
#    $sheet_diff->write( 0, 5 + $#seq_files + $pair_count, "Description", $my_head_diff );
#    $sheet_diff->set_column( "$columns_of_gote:$columns_of_gote", 30 );
    $columns_of_gote++;
    $sheet_anno->write( 0, 7 + $#seq_files + $pair_count, "Gene_Ontology", $my_head );
    $sheet_anno->set_column( "$columns_of_gote:$columns_of_gote", 50 );
#    $sheet_diff->write( 0, 6 + $#seq_files + $pair_count, "Gene_Ontology", $my_head_diff );
#    $sheet_diff->set_column( "$columns_of_gote:$columns_of_gote", 50 );
    my $line_anno = 0;
#    my $line_diff = 1;

    foreach my $acc_id (keys %isoform_list) {
        $line_anno++;
        $sheet_anno->write ($line_anno, 0, $isoform_list{$acc_id}{'chr'});
        $sheet_anno->write ($line_anno, 1, $isoform_list{$acc_id}{'gene_name'});
        $sheet_anno->write ($line_anno, 2, $acc_id);
        print VENN "$acc_id";
        $sheet_anno->write ($line_anno, 3, $isoform_list{$acc_id}{'gi'});

        for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
            my $q_id = "q".$i;
            if (not exists $rpkm{$samples{$q_id}}) {
               $rpkm{$samples{$q_id}} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            }
            $sheet_anno->write( $line_anno, 3+$i, $isoform_list{$acc_id}{$samples{$q_id}});
            if (not exists $isoform_list{$acc_id}{$samples{$q_id}}) {
                $isoform_list{$acc_id}{$samples{$q_id}} = 0;
                $rpkm{$samples{$q_id}}->[0]++;
                print VENN "\tNA";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} == 0) {
                $rpkm{$samples{$q_id}}->[0]++;
                print VENN "\tNA";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 10) {
                $rpkm{$samples{$q_id}}->[1]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 20) {
                $rpkm{$samples{$q_id}}->[2]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 30) {
                $rpkm{$samples{$q_id}}->[3]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 40) {
                $rpkm{$samples{$q_id}}->[4]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 50) {
                $rpkm{$samples{$q_id}}->[5]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 60) {
                $rpkm{$samples{$q_id}}->[6]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 70) {
                $rpkm{$samples{$q_id}}->[7]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 80) {
                $rpkm{$samples{$q_id}}->[8]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 90) {
                $rpkm{$samples{$q_id}}->[9]++;
                print VENN "\t$acc_id";
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 100) {
                $rpkm{$samples{$q_id}}->[10]++;
                print VENN "\t$acc_id";
            }
            else {
                $rpkm{$samples{$q_id}}->[11]++;
                print VENN "\t$acc_id";
            }
        }
        print VENN "\n";
        $pair_count = 0;
#        my $p_value_ok = 0;
        foreach my $pair_id (keys %pair_id_list) {
            $sheet_anno->write( $line_anno, 5+$#seq_files+$pair_count, $isoform_list{$acc_id}{$pair_id});
#            if ($isoform_list{$acc_id}{$pair_id} < 0.01) {
#                $p_value_ok = 1;
#                $sheet_diff->write ($line_diff, 0, $isoform_list{$acc_id}{'chr'});
#                $sheet_diff->write ($line_diff, 1, $isoform_list{$acc_id}{'gene_name'});
#                $sheet_diff->write ($line_diff, 2, $acc_id);
#                $sheet_diff->write ($line_diff, 3, $isoform_list{$acc_id}{'gi'});
#                for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
#                    my $q_id = "q".$i;
#                    $sheet_diff->write( $line_diff, 3+$i, $isoform_list{$acc_id}{$samples{$q_id}});
#                }
#                $sheet_diff->write( $line_diff, 5+$#seq_files+$pair_count, $isoform_list{$acc_id}{$pair_id});
#            }
            $pair_count++;
        }
        my $dbh3 = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
        my $sth = $dbh3->prepare("SELECT pathway FROM kegg_pathway.species_genename_pathway WHERE gene_name = \'$isoform_list{$acc_id}{'gene_name'}\' and species = \'$spe\'");
        $sth->execute() || warn "Gene_Name: $isoform_list{$acc_id}{'gene_name'}\tSpecies: $spe\n";
        my @row = $sth->fetchrow_array ;
        my $pathway = pop(@row);
        $sheet_anno->write ($line_anno, 5+$#seq_files+$pair_count, $pathway);
        $sheet_anno->write ($line_anno, 6+$#seq_files+$pair_count, $isoform_list{$acc_id}{'desc'});
        $sheet_anno->write ($line_anno, 7+$#seq_files+$pair_count, $isoform_list{$acc_id}{'go_desc'});
#        if ($p_value_ok == 1) {
#            $sheet_diff->write ($line_diff,  5+$#seq_files+$pair_count, $isoform_list{$acc_id}{'desc'});
#            $sheet_diff->write ($line_diff,  6+$#seq_files+$pair_count, $isoform_list{$acc_id}{'go_desc'});
#            $line_diff++;
#        }
    }
    close(VENN);
    foreach my $venn_pair_id (keys %pair_id_list) {
        my ($id1, $id2) = split(/_to_/, $venn_pair_id);
        open (TMP_R, ">$venn_pair_id\_venn.R") or die $!;
        print TMP_R "library(VennDiagram)\nvenn_file <- read.table(\"venn.matrix\", header=TRUE, check.names=FALSE)\n";
        print TMP_R "arg1 <- venn_file\$\"$id1\"\[!is.na(venn_file\$\"$id1\")\]\narg2 <- venn_file\$\"$id2\"\[!is.na(venn_file\$\"$id2\")\]\n";
        print TMP_R "title <- paste(\"Venn of\", \"$id1\", \"and\", \"$id2\", sep=\" \")\n";
        print TMP_R "venn.diagram(list( \"$id1\"=arg1, \"$id2\"=arg2), \"$venn_pair_id\_venn.tiff\", main=title, scaled=FALSE, main.cex=2, col=\"transparent\", fill=c(\"cornflowerblue\", \"darkorchid1\"), alpha=.4, height=768, width=768, resolution=100, unit=\"px\" )";
        close(TMP_R);
        system("Rscript $venn_pair_id\_venn.R");
        system("tiff2pdf -d -o $venn_pair_id\_venn.pdf $venn_pair_id\_venn.tiff"); 
    }

    $line_anno = 0;
    $sheet_summ->write( 0, 0, "RPKM Destribution", $my_merge_rpkm );
    $sheet_summ->write_blank( 0, 1,  $my_merge_rpkm );
    $sheet_summ->write_blank( 0, 2,  $my_merge_rpkm );
    $sheet_summ->write( 1, 0, "Range", $my_head_rpkm );
    $sheet_summ->write( 1, 1, "Number", $my_head_rpkm );
    $sheet_summ->write( 1, 2, "Ratio", $my_head_rpkm );

    $line_summ++;
    foreach my $level1 (keys %all_go) {
        $sheet_gote->write($line_summ, 0, $level1, $my_format_go );
        foreach my $level2 (keys %{$all_go{$level1}}) {
            $sheet_gote->write($line_summ, 1, $level2, $my_format_go );
            my $samples_number = 0;
            if ($level1 eq "molecular_function") {
                print MF "$level2";
            }
            elsif ($level1 eq "cellular_component") {
                print CC "$level2";
            }
            elsif ($level1 eq "biological_process") {
                print BP "$level2";
            }
            else {
                die "level1 of GO err!\n";
            }
            for (my $i = 0 ; $i <= $#seq_files; $i++) {
                my $seq = $seq_files[$i];
                $seq =~ s/\..+//;
                $seq =~ s/ //g;
                $seq =~ s/_R1//g;
                $seq =~ s/_read1//g;
                if (exists $all_go{$level1}{$level2}{$seq}) {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_head_go);
                    $sheet_gote->write($line_summ, 2+$samples_number, $all_go{$level1}{$level2}{$seq} );
                    if ($level1 eq "molecular_function") {
                        print MF "\t$all_go{$level1}{$level2}{$seq}";
                    }
                    elsif ($level1 eq "cellular_component") {
                        print CC "\t$all_go{$level1}{$level2}{$seq}";
                    }
                    elsif ($level1 eq "biological_process") {
                        print BP "\t$all_go{$level1}{$level2}{$seq}";
                    }
                    else {
                        die "level1 of GO err!\n";
                    }
                }
                else {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_head_go);
                    $sheet_gote->write($line_summ, 2+$samples_number, "0");
                    if ($level1 eq "molecular_function") {
                        print MF "\t0";
                    }
                    elsif ($level1 eq "cellular_component") {
                        print CC "\t0";
                    }
                    elsif ($level1 eq "biological_process") {
                        print BP "\t0";
                    }
                    else {
                        die "level1 of GO err!\n";
                    }
                }
                $samples_number++;
            }
            if ($level1 eq "molecular_function") {
                print MF "\n";
            }
            elsif ($level1 eq "cellular_component") {
                print CC "\n";
            }
            elsif ($level1 eq "biological_process") {
                print BP "\n";
            }
            else {
                die "level1 of GO err!\n";
            }
            $line_summ++;
        }
    }
    close(BP);
    close(CC);
    close(MF);
    system("Rscript ~/workdir/my_script/go.R  bp.matrix cc.matrix mf.matrix GO_Plot.pdf");

    my $lines_of_gote = $line_summ--;
    $columns_of_gote = "B";
    my $chart = $excel_dist->add_chart( type => 'column', embedded => 1 );

    $line_summ = 1;
    my $line_id = 3;
    foreach my $sample_name (keys %rpkm) {
        print RRPKM "$sample_name\n";
        $line_summ++;
        $sheet_summ->write( $line_summ, 0, "$sample_name", $my_format_rpkm );
        my $sample_end;
        for (my $i = 0; $i <= 11; $i++ ) {
            my $rpkm_val = ${$rpkm{$sample_name}}[$i];
            $line_summ++;
            $line_id = $line_summ + 1;
            if ($i == 0) {
                $sample_end = $line_id+12;
                $sheet_summ->write( $line_summ, 0, "0", $my_format_rpkm );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val");
                print RRPKM "$rpkm_val\n";
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end", $num_format);
            }
            elsif ($i <= 10) {
                my $range = $i * 10;
                my $range1 = $range - 10;
                $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format_rpkm );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val");
                print RRPKM "$rpkm_val\n";
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end", $num_format);
            }
            elsif ($i == 11) {
                $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format_rpkm );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val", );
                print RRPKM "$rpkm_val\n";
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end", $num_format );
            }
        }
        my $sample_start = $sample_end - 12;
        $sample_end--;
        $chart->add_series(
            name       => "$sample_name",
            categories => "=Summary!\$A\$$sample_start:\$A\$$sample_end",
            values     => "=Summary!\$B\$$sample_start:\$B\$$sample_end",
        );
        $line_summ++;
        $sheet_summ->write( $line_summ, 0, "Total:", $my_format_rpkm );
        $sheet_summ->write( $line_summ, 1, "=SUM(B$sample_start:B$sample_end)" );
        $sheet_summ->write( $line_summ, 2, "100%" );
        $line_summ++;
    }
    close(RRPKM);
    system("Rscript ~/workdir/my_script/rpkm.R rpkm.matrix RPKM_Distribution.pdf");

    $chart->set_title ( name => 'RPKM Distribution' );
    $chart->set_y_axis( name => 'Number' );
    $chart->set_x_axis( name => 'RPKM Range' );
    $chart->set_style( 21 );

    $sheet_summ->insert_chart( "A$line_summ", $chart, 0, 0, 2, 2 ); 
    my $chart_go = $excel_gote->add_chart( type => 'column', embedded => 1 );
    for (my $i = 0; $i <= $#seq_files; $i++) {
        $columns_of_gote++;
        $chart_go->add_series(
            name       => "=Gene_Ontology!\$$columns_of_gote\$2",
            categories => "=Gene_Ontology!\$A\$3:\$B\$$lines_of_gote",
            values     => "=Gene_Ontology!\$$columns_of_gote\$3:\$$columns_of_gote\$$lines_of_gote",
        );
    }
    $lines_of_gote++;
    $lines_of_gote++;
    $chart_go->set_title ( name => 'GO Distribution' );
    $chart_go->set_x_axis( name => "Catalogue" );
    $chart_go->set_y_axis( name => 'Number' );
    $chart_go->set_style( 21 );
    $sheet_gote->insert_chart( "A$lines_of_gote", $chart_go, 0, 0, 2.5, 3 ); 
    $excel_dist->close();
    $excel->close();
    $excel_gote->close();

    if ($pnt eq "yes") {
        my $input_reference = Bio::SeqIO->new(-file => "$ref",-format => 'Fasta');
        my $output_reference = Bio::SeqIO->new(-file => ">new_transcript.fa",-format => 'Fasta');
        while (my $seqobj = $input_reference->next_seq()) {
            foreach my $new_seq_trans_id (keys %transcriptome) {
                my ($chr, $pos) = split(/:/, $transcriptome{$new_seq_trans_id}{'chr'});
                print $chr,"\t",$seqobj->id(),"\n";
                if ($chr ne $seqobj->id()) {
                    next;
                }
                my ($start_pos, $stop_pos) = split(/-/, $pos);
                my $seqobj_out = Bio::PrimarySeq->new ( -seq => $seqobj->subseq($start_pos, $stop_pos), -id  => $new_seq_trans_id, -alphabet => 'dna');
                $output_reference->write_seq($seqobj_out);
            }
        }
        system("blastall -p blastn -d $db_nt -e 1e-20 -a 16 -b 10 -m 9 -i new_transcript.fa -o new2nt.blastn");
        system("blastall -p blastx -d $db_sw -e 1e-20 -a 16 -b 10 -m 9 -i new_transcript.fa -o new2sw.blastx");
        my $dbh1 = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
        open (NTB, "new2nt.blastn") or die $!;
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
            }
        }
        close(NTB);
        open (NTB, "new2sw.blastx") or die $!;
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
    
        open ("NEWT", ">New_Predicted_Transcript.gtf") or die $!;
        open ("NEWG", ">New_Predicted_Gene.gtf") or die $!;
        my $excel_newt = Excel::Writer::XLSX -> new ( "New_Transcript.xlsx" );
        my $sheet_newt = $excel_newt->add_worksheet( "New_Transcript_anno" );
        my $excel_newg = Excel::Writer::XLSX -> new ( "New_Gene.xlsx" );
        my $sheet_newg = $excel_newg->add_worksheet( "New_Gene_anno" );
        my $newt_head = $excel_newt->add_format( fg_color => 0x30, align => 'center', bold => 1);
        my $newg_head = $excel_newg->add_format( fg_color => 0x30, align => 'center', bold => 1);
        $sheet_newt->write( 0, 0, "Transcript_ID", $newt_head );
        $sheet_newt->write( 0, 1, "Gene_Name", $newt_head );
        $sheet_newt->set_column( 'A:A', 18 );
        $sheet_newt->set_column( 'B:B', 12 );
        $sheet_newg->write( 0, 0, "Transcript_ID", $newg_head );
        $sheet_newg->write( 0, 1, "Gene_Name", $newg_head );
        $sheet_newg->set_column( 'A:A', 18 );
        $sheet_newg->set_column( 'B:B', 12 );
    
        $columns_of_gote = "C";
        for (my $i = 0 ; $i <= $#seq_files; $i++) {
            my $seq = $seq_files[$i];
            $seq =~ s/\..+//;
            $seq =~ s/ //g;
            $seq =~ s/_R1//g;
            $seq =~ s/_read1//g;
            $sheet_newt->write( 0, 2+$i, "RPKM_$seq", $newt_head );
            $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 15 );
            $sheet_newg->write( 0, 2+$i, "RPKM_$seq", $newg_head );
            $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 15 );
            $columns_of_gote++;
        }
        $pair_count = 0;
        foreach (keys %pair_id_list) {
            $sheet_newt->write( 0, 3+$#seq_files+$pair_count, "q-Value_$_", $newt_head );
            $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 25 );
            $sheet_newg->write( 0, 3+$#seq_files+$pair_count, "q-Value_$_", $newg_head );
            $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 25 );
            $columns_of_gote++;
            $pair_count++;
        }
        
        $sheet_newt->write( 0, 3 + $#seq_files + $pair_count, "Best_Hit_to_NT_ID", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 40 );
        $sheet_newg->write( 0, 3 + $#seq_files + $pair_count, "Best_Hit_to_NT_ID", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 40 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 4 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_ID", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 30 );
        $sheet_newg->write( 0, 4 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_ID", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 30 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 5 + $#seq_files + $pair_count, "Best_Hit_to_NT_Evalue", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $sheet_newg->write( 0, 5 + $#seq_files + $pair_count, "Best_Hit_to_NT_Evalue", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 6 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Evalue", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $sheet_newg->write( 0, 6 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Evalue", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 7 + $#seq_files + $pair_count, "Best_Hit_to_NT_Desc", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $sheet_newg->write( 0, 7 + $#seq_files + $pair_count, "Best_Hit_to_NT_Desc", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 8 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Desc", $newt_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $sheet_newg->write( 0, 8 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Desc", $newg_head );
        $sheet_newg->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $columns_of_gote++;
    
        $line_anno = 0;
        my $new_gene_line = 0;
        foreach my $acc_id (keys %transcriptome) {
            if ($transcriptome{$acc_id}{'gene_name'} ne "-") {
                $line_anno++;
                print NEWT $merged_gtf{$acc_id};
                $sheet_newt->write ($line_anno, 0, $acc_id);
                $sheet_newt->write ($line_anno, 1, $transcriptome{$acc_id}{'gene_name'});
                for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
                    my $q_id = "q".$i;
                    $sheet_newt->write( $line_anno, 1+$i, $transcriptome{$acc_id}{$samples{$q_id}});
                }
                $pair_count = 0;
                foreach my $pair_id (keys %pair_id_list) {
                    $sheet_newt->write( $line_anno, 3+$#seq_files+$pair_count, $transcriptome{$acc_id}{$pair_id});
                    $pair_count++;
                }
                $sheet_newt->write ($line_anno,  3+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_id'});
                $sheet_newt->write ($line_anno,  4+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_id'});
                $sheet_newt->write ($line_anno,  5+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_ev'});
                $sheet_newt->write ($line_anno,  6+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_ev'});
                $sheet_newt->write ($line_anno,  7+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_desc'});
                $sheet_newt->write ($line_anno,  8+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_desc'});
            }
            else {
                $new_gene_line++;
                print NEWG $merged_gtf{$acc_id};
                $sheet_newg->write ($new_gene_line, 0, $acc_id);
                $sheet_newg->write ($new_gene_line, 1, $transcriptome{$acc_id}{'gene_name'});
                for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
                    my $q_id = "q".$i;
                    $sheet_newg->write( $new_gene_line, 1+$i, $transcriptome{$acc_id}{$samples{$q_id}});
                }
                $pair_count = 0;
                foreach my $pair_id (keys %pair_id_list) {
                    $sheet_newg->write( $new_gene_line, 3+$#seq_files+$pair_count, $transcriptome{$acc_id}{$pair_id});
                    $pair_count++;
                }
                $sheet_newg->write ($new_gene_line,  3+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_id'});
                $sheet_newg->write ($new_gene_line,  4+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_id'});
                $sheet_newg->write ($new_gene_line,  5+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_ev'});
                $sheet_newg->write ($new_gene_line,  6+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_ev'});
                $sheet_newg->write ($new_gene_line,  7+$#seq_files+$pair_count, $transcriptome{$acc_id}{'nt_desc'});
                $sheet_newg->write ($new_gene_line,  8+$#seq_files+$pair_count, $transcriptome{$acc_id}{'sw_desc'});
            }
        }
        close (NEWT);
        close (NEWG);
    }

    my $my_head_godi = $excel_godi->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_godi = $excel_godi->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_godi = $excel_godi->add_format( fg_color => 0x2C, align => 'center');
    my $my_head_diff = $excel_diff->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge_diff = $excel_diff->add_format( center_across => 1, fg_color => 0x30, align => 'center', bold => 1);
    my $my_format_diff = $excel_diff->add_format( fg_color => 0x2C, align => 'center');
    my $excel_read = Spreadsheet::XLSX -> new ( "RPKM_table.xlsx" );
    my $dbh2 = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
    foreach my $pair_diff (keys %pair_id_list) {
        my ($diff_sample1, $diff_sample2) = split(/_to_/, $pair_diff);
        my $sheet_diff = $excel_diff->add_worksheet( "Diff_Express_Gene_$diff_sample1\_$diff_sample2" );
        if ($hem eq "yes") {
              open(HEM, ">$diff_sample1\_$diff_sample2.heatmap") or die $!;
              print HEM " \t$diff_sample1\t$diff_sample2\n";
        }
        $sheet_diff->write( 0, 0, "Chromosome", $my_head_diff );
        $sheet_diff->write( 0, 1, "Gene_Name", $my_head_diff );
        $sheet_diff->set_column( 'A:A', 16 );
        $sheet_diff->set_column( 'B:B', 16 );
        $sheet_diff->set_column( 'C:C', 15 );
        $sheet_diff->set_column( 'D:D', 10 );
        $sheet_diff->set_column( 'E:E', 15 );
        $sheet_diff->write( 0, 2, "Accession_Num", $my_head_diff );
        $sheet_diff->write( 0, 3, "GI", $my_head_diff );
        my $wirte_row = 1;

        my $sheet_godi = $excel_godi->add_worksheet( "$pair_diff" );
        $sheet_godi->write( 0, 0, "GO Ontology", $my_merge_godi);
        $sheet_godi->set_column( 'A:A', 20 );
        $sheet_godi->set_column( 'B:B', 50 );
        $sheet_godi->set_column( 'C:C', 16 );
        $sheet_godi->set_column( 'D:D', 16 );
        $sheet_godi->set_column( 'E:E', 16 );
        $sheet_godi->set_column( 'F:F', 16 );
        $sheet_godi->set_column( 'G:G', 16 );
        $sheet_godi->set_column( 'H:H', 16 );
        $sheet_godi->write_blank( 0, 1,  $my_merge_godi );
        $sheet_godi->write_blank( 0, 2,  $my_merge_godi );
        $sheet_godi->write( 1, 0, "Type", $my_format_godi );
        $sheet_godi->write( 1, 1, "Description", $my_format_godi );
        $sheet_godi->write( 1, 2, "Number_$diff_sample1", $my_head_godi );
        $sheet_godi->write( 1, 3, "Number_$diff_sample2", $my_head_godi );
        my %go_sample = ();
       
        foreach my $sheet (@{$excel_read -> {Worksheet}}) {
            $sheet -> {MaxRow} ||= $sheet -> {MinRow};
            $sheet -> {MaxCol} ||= $sheet -> {MinCol};
            my $max_col = $sheet -> {MaxCol};
            my ($col_read1, $col_read2, $col_p) = (0, 0, 0);
            
#            print "\n\n", $sheet -> {MaxCol} , "\t $max_col\n\n";
            foreach my $col (4 ..  $sheet -> {MaxCol}) {
                my $cell = $sheet -> {Cells} [0] [$col];
                my $tmp = $cell->{Val};
#                print $tmp,"\t";
                if ($tmp eq "RPKM_".$diff_sample1) {
                    $col_read1 = $col;
                    $sheet_diff->write( 0, 4, "RPKM_$diff_sample1", $my_head_diff );
                }
                elsif ($tmp eq "RPKM_".$diff_sample2) {
                    $col_read2 = $col;
                    $sheet_diff->write( 0, 5, "RPKM_$diff_sample2", $my_head_diff );
                }
                elsif ($tmp eq "q-Value_".$pair_diff) {
                    $col_p = $col;
                }
            }
            $sheet_diff->write( 0, 6, "RPKM_Ratio", $my_head_diff );
            $sheet_diff->write( 0, 7, "q-Value", $my_head_diff );
            $sheet_diff->write( 0, 8, "KEGG_Pathway", $my_head_diff );
            $sheet_diff->write( 0, 9, "Description", $my_head_diff );
            $sheet_diff->write( 0, 10, "Gene_Ontology", $my_head_diff );
            if ($col_read1 == 0 || $col_read2 == 0 || $col_p == 0) {
                 die "Read col err!\n";
            }
    
            foreach my $row ( 1 .. $sheet -> {MaxRow}) {
                 my $cell = $sheet -> {Cells} [$row] [$col_p];
                 my $q_val = $cell->{Val};
                 if (not $q_val) {
#                     print "q_value not exist in line $row\n";
                     next;
                 }
                 elsif ($q_val < 0.05) {
                     $cell = $sheet -> {Cells} [$row] [$max_col];
                     my  @row;
                     if ($cell->{Val}) {
                         @row = split(/; /, $cell->{Val});
                     }
                     my $acc_id_diff;
                     my $hem_gene_name; 
                     for (my $i = 0; $i<3; $i++) {
                         $cell = $sheet -> {Cells} [$row] [$i];
                         $acc_id_diff = $cell->{Val};
                         if ($i == 1) {
                             $hem_gene_name = $acc_id_diff;
                         }
                         $sheet_diff->write( $wirte_row, $i, $acc_id_diff);
                     }
                     $sheet_diff->write( $wirte_row, 3, $isoform_list{$acc_id_diff}{'gi'});
    
                     $cell = $sheet -> {Cells} [$row] [$col_read1];
                     my $rpkm_1 = $cell->{Val};
                     $sheet_diff->write( $wirte_row, 4, $cell->{Val});
                     $cell = $sheet -> {Cells} [$row] [$col_read2];
                     my $rpkm_2 = $cell->{Val};
                     $sheet_diff->write( $wirte_row, 5, $cell->{Val});
                     $cell = $sheet -> {Cells} [$row] [$col_p];
                     if ($hem eq "yes") {
                         print HEM "$hem_gene_name\t$rpkm_1\t$rpkm_2\n";
                     }
                     if ($rpkm_1 != 0 && $rpkm_2 != 0) {
                         $sheet_diff->write( $wirte_row, 6, sprintf('%5.2f', $rpkm_1/$rpkm_2));
                     }
                     else {
                         $sheet_diff->write( $wirte_row, 6, "NULL");
                     }
                     $sheet_diff->write( $wirte_row, 7, $q_val);
                     $cell = $sheet -> {Cells} [$row] [$max_col-2];
                     $sheet_diff->write( $wirte_row, 8, $cell->{Val});
                     $cell = $sheet -> {Cells} [$row] [$max_col-1];
                     $sheet_diff->write( $wirte_row, 9, $cell->{Val});
                     $cell = $sheet -> {Cells} [$row] [$max_col];
                     $sheet_diff->write( $wirte_row, 10, $cell->{Val});
                     $wirte_row++;
                     
                     foreach my $go_id (@row) {
                         my $sth = $dbh2->prepare("select term_type,description from gene_annotation.level2desc where go = \'$go_id\'");
                         $sth->execute();
                         my $rows_ref = $sth->fetchall_arrayref;
                         while (my $row = pop(@$rows_ref)) {
                             if (exists $go_sample{${$row}[0]}{${$row}[1]}) {
                                 if ($rpkm_1 != 0) {
                                     $go_sample{${$row}[0]}{${$row}[1]}{'s1'}++;
                                 }
                                 if ($rpkm_2 != 0)  {
                                     $go_sample{${$row}[0]}{${$row}[1]}{'s2'}++;
                                 }
                             }
                             else {
                                 if ($rpkm_1 != 0) {
                                     $go_sample{${$row}[0]}{${$row}[1]}{'s1'} = 1;
                                 }
                                 if ($rpkm_2 != 0)  {
                                     $go_sample{${$row}[0]}{${$row}[1]}{'s2'} = 1;
                                 }
                             }
                         }
                     }
                 }
             }
         }
         if ($hem eq "yes") {
             close(HEM);
             system("Rscript ~/workdir/my_script/heatmap.2_plot.R $diff_sample1\_$diff_sample2.heatmap $diff_sample1\_$diff_sample2\_heatmap.pdf");
         }
         

         foreach my $acc_id (keys %transcriptome) {
             if ($transcriptome{$acc_id}{$pair_diff} <= 0.05 && $transcriptome{$acc_id}{'gene_name'} ne '-') {
                 $sheet_diff->write( $wirte_row, 1, $transcriptome{$acc_id}{'gene_name'});
                 $sheet_diff->write( $wirte_row, 2, $acc_id);
                 $sheet_diff->write( $wirte_row, 4, $transcriptome{$acc_id}{$diff_sample1});
                 $sheet_diff->write( $wirte_row, 5, $transcriptome{$acc_id}{$diff_sample2});
                 if ($transcriptome{$acc_id}{$diff_sample2} != 0 && $transcriptome{$acc_id}{$diff_sample1} != 0 ) {
                     $sheet_diff->write( $wirte_row, 6, sprintf('%5.2f', $transcriptome{$acc_id}{$diff_sample1}/$transcriptome{$acc_id}{$diff_sample2}));
                 }
                 else {
                     $sheet_diff->write( $wirte_row, 6, "NULL");
                 }
                 my $sth = $dbh->prepare("SELECT pathway FROM kegg_pathway.species_genename_pathway WHERE gene_name = \'$transcriptome{$acc_id}{'gene_name'}\' and species = \'$spe\'");
                 $sth->execute();
                 my @row = $sth->fetchrow_array ;
                 my $pathway = pop(@row);
                 $sheet_diff->write( $wirte_row, 7, $transcriptome{$acc_id}{$pair_diff});
                 $sheet_diff->write( $wirte_row, 8, $pathway);
                 $wirte_row++;
             }
         }
         $wirte_row = 2;
         foreach my $level1 (keys %go_sample) {
             $sheet_godi->write($wirte_row, 0, $level1, $my_format_godi );
             foreach my $level2 (keys %{$go_sample{$level1}}) {
                 $sheet_godi->write($wirte_row, 1, $level2, $my_format_godi );
                 if (exists $go_sample{$level1}{$level2}{'s1'}) {
                     $sheet_godi->write($wirte_row, 2, $go_sample{$level1}{$level2}{'s1'} );
                 }
                 else {
                     $sheet_godi->write($wirte_row, 2, "0");
                 }
                 if (exists $go_sample{$level1}{$level2}{'s2'}) {
                     $sheet_godi->write($wirte_row, 3, $go_sample{$level1}{$level2}{'s2'} );
                 }
                 else {
                     $sheet_godi->write($wirte_row, 3, "0");
                 }
                 $wirte_row++;
             }
         }
        $wirte_row--;
#        my $chart_godi = $excel_godi->add_chart( type => 'column', embedded => 1 );
#        $chart_godi->add_series(
#            name       => "=Gene_Ontology!\$C\$2",
#            categories => "=Gene_Ontology!\$A\$3:\$B\$$wirte_row",
#            values     => "=Gene_Ontology!\$C\$3:\$C\$$wirte_row",
#        );
#        $chart_godi->add_series(
#            name       => "=Gene_Ontology!\$D\$2",
#            categories => "=Gene_Ontology!\$A\$3:\$B\$$wirte_row",
#            values     => "=Gene_Ontology!\$D\$3:\$D\$$wirte_row",
#        );
#        $chart_godi->set_title ( name => 'GO Distribution' );
#        $chart_godi->set_x_axis( name => "Catalogue" );
#        $chart_godi->set_y_axis( name => 'Number' );
#        $chart_godi->set_style( 21 );
#        $sheet_godi->insert_chart( "A$wirte_row", $chart_godi, 0, 0, 2.5, 3 ); 
    }
}
#system("rm -rf /dev/shm/*.matrix");
