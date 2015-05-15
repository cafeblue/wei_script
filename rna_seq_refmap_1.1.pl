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

##################################################
# Example of config.txt file:
#
# $ cat config.txt
#
# [lib_se]
# q=./sample1.fq
# READSLENG=36
#
# [lib_se]
# q=./sample2.fq
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
}


#  if only one sample, comparison is useless.
if ($#seq_files == 0) {
    my $seq_name = pop(@seq_files);
    my $seq = $seq_name;
    $seq =~ s/\..+//;
    $seq =~ s/ //g;
    my $seq_name2;
    my $ins;

    # if lib is a PE lib, parameters for tophat and cufflinks are different.
    if ($#insertsize > -1) {
        $seq_name2 = pop(@seq_files2);
        $ins = pop(@insertsize);
        system("tophat -o tophat_$seq  -r $ins --solexa-quals -p 16 -G $gtf $ref $seq_name $seq_name2");
        system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -G $gtf ./tophat_$seq/accepted_hits.bam");
    }
    else {
        system("tophat -o tophat_$seq --solexa1.3-quals -p 16 -G $gtf $ref $seq_name");
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
    $sheet_anno->write( 0, 1, "Gene_Name", $my_head );
    $sheet_anno->write( 0, 2, "Accession_Num", $my_head );
    $sheet_anno->write( 0, 3, "GI", $my_head );
    $sheet_anno->write( 0, 4, "Exon_Length", $my_head );
    $sheet_anno->write( 0, 5, "RPKM", $my_head );
    $sheet_anno->write( 0, 6, "Description", $my_head );
    $sheet_anno->write( 0, 7, "Gene_Ontology", $my_head );
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
        $sheet_anno->write ( $line_anno, 6, "$desc" , $my_format);
        $sheet_anno->write ( $line_anno, 7, "$go_desc" , $my_format);

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
        print "$. of $total_lines ...  ";
        my $percent = sprintf('%5.2f', $./$total_lines);
        print $percent,'%', "\cM";
    }

    # write the GO chart file.
    $line_summ++;
    foreach my $level1 (keys %all_go) {
        $sheet_gote->write($line_summ, 0, $level1, $my_format_go );
        foreach my $level2 (keys %{$all_go{$level1}}) {
            $sheet_gote->write($line_summ, 1, $level2, $my_format_go );;
            $sheet_gote->write($line_summ, 2, $all_go{$level1}{$level2}, $my_format_go );
            $line_summ++;
        }
    }

    # write the discription of RPKM file.
    my $lines_of_gote = $line_summ--;
    $lines_of_gote--;
    $line_summ = 1;
    foreach my $rpkm_val (shift(@rpkm)) {
        $line_summ++;
        if ($line_summ == 2) {
            $sheet_summ->write( $line_summ, 0, "0", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            $sheet_summ->write( $line_summ, 2, '=B3/B15', $num_format );
        }
        elsif ($line_summ <= 12) {
            my $range = ($line_summ - 2) * 10;
            my $range1 = $range - 10;
            my $line_id = $line_summ + 1;
            $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            $sheet_summ->write( $line_summ, 2, "=B$line_id/B15", $num_format );
        }
        elsif ($line_summ == 13) {
            $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format_rpkm );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val" );
            $sheet_summ->write( $line_summ, 2, "=B14/B15", $num_format);
        }
        else {
            die "Something Wrong\?\n";
        }
    }
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

else {
    my $all_bamfiles = "";
    my $all_gtffiles = "";
    my %transcriptome;
    my %rpkm;
    my %all_go;
    my %isoform_list;
    my $p_sample = 0;
    my %samples;
    for (my $i = 0 ; $i <= $#seq_files; $i++) {
        $p_sample++;
        my $id = "q".$p_sample;
        my $seq = $seq_files[$i];
        $seq =~ s/\..+//;
        $seq =~ s/ //g;
        $samples{$id} = $seq;
        if ($pnt eq "yes") {   
            if ($#insertsize > -1) {
                system("tophat -o tophat_$seq -r $insertsize[$i] --solexa-quals -p 16 -G $gtf $ref $seq_files[$i] $seq_files2[$i]");
                system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -g $gtf ./tophat_$seq/accepted_hits.bam");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
                $all_gtffiles .= "cufflinks_$seq/transcripts.gtf\n";
            }
            else {
                system("tophat -o tophat_$seq --solexa1.3-quals -p 16 -G $gtf $ref $seq_files[$i]");
                system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -g $gtf ./tophat_$seq/accepted_hits.bam");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
                $all_gtffiles .= "cufflinks_$seq/transcripts.gtf\n";
            }
        }
        else {
            if ($#insertsize > -1) {
                system("tophat -o tophat_$seq -r $insertsize[$i] --solexa-quals -p 16 -G $gtf $ref $seq_files[$i] $seq_files2[$i]");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
            }
            else {
                system("tophat -o tophat_$seq --solexa1.3-quals -p 16 -G $gtf $ref $seq_files[$i]");
                $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
            }
        }
    }

    my %old_id;
    if ($pnt eq "yes") {
        open (GTF_LST, ">gtf_lst.txt") or die $!;
        print GTF_LST $all_gtffiles;
        close(GTF_LST);
        system("cuffmerge -o cuffmerge_all -g $gtf -s $ref -p 16 gtf_lst.txt");
        system("cuffdiff --no-update-check -p 16 -o cuffdiff_all ./cuffmerge_all/merged.gtf $all_bamfiles");
    
        open (GTF_REL, "./cuffmerge_all/merged.gtf") or die $!;
        while (<GTF_REL>) {
            my ($trans_id, $old_trans1, $old_trans2) = (split(/;/, $_))[1,3,4];
            $trans_id =~ s/ //g;
            $trans_id =~ s/transcript_id//;
            $trans_id =~ s/"//g;
            if ($old_trans1 =~ /oId/) {
                $old_trans1 =~ s/ //g;
                $old_trans1 =~ s/oId//;
                $old_trans1 =~ s/"//g;
                $old_id{$trans_id} = $old_trans1;
            }
            else {
                $old_trans2 =~ s/ //g;
                $old_trans2 =~ s/oId//;
                $old_trans2 =~ s/"//g;
                $old_id{$trans_id} = $old_trans2;
            }
        }
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
    my %pair_id_list;
    my $dbh = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
    while (<RPKM>) {
        my @lines = split(/\t/, $_);
        if ($pnt eq "yes") {
            if ($old_id{$lines[0]} =~ /^CUFF/) {
                $transcriptome{$lines[0]}{'chr'} = $lines[3];
                $transcriptome{$lines[0]}{'gene_name'} = $lines[2];
                $transcriptome{"$lines[0]"}{$samples{$lines[4]}} = $lines[7];
                $transcriptome{"$lines[0]"}{$samples{$lines[5]}} = $lines[8];
                my $pair_id = $samples{$lines[4]}."_to_".$samples{$lines[5]};
                $transcriptome{"$lines[0]"}{$pair_id} = $lines[12];
                if (not exists $pair_id_list{$pair_id}) {
                    $pair_id_list{$pair_id} = 1;
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
            print "\n",$lines[0],"\n";
        }
        $sth = $dbh->prepare("SELECT description FROM gene_annotation.gi2description WHERE gi = \'$gi\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        my $desc = pop(@row);
        $sth = $dbh->prepare("SELECT goid FROM gene_annotation.gi2go WHERE gi = \'$gi\'");
        $sth->execute();
        @row =  ();
        my $rows_ref = $sth->fetchall_arrayref;
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
        if (not exists $pair_id_list{$pair_id}) {
            $pair_id_list{$pair_id} = 1;
        }
        $isoform_list{"$lines[0]"}{'gi'} = "\=HYPERLINK\(\"http\:\/\/www\.ncbi\.nlm\.nih\.gov\/nuccore\/$gi\",\"$gi\"\)";
        $isoform_list{"$lines[0]"}{'desc'} = $desc;
        print "$.\tof $total_lines ...  \t", sprintf ('%5.2f', $./$total_lines*100), "%\cM";
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
    $sheet_anno->write( 0, 5 + $#seq_files + $pair_count, "Description", $my_head );
    $sheet_anno->set_column( "$columns_of_gote:$columns_of_gote", 30 );
#    $sheet_diff->write( 0, 5 + $#seq_files + $pair_count, "Description", $my_head_diff );
#    $sheet_diff->set_column( "$columns_of_gote:$columns_of_gote", 30 );
    $columns_of_gote++;
    $sheet_anno->write( 0, 6 + $#seq_files + $pair_count, "Gene_Ontology", $my_head );
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
        $sheet_anno->write ($line_anno, 3, $isoform_list{$acc_id}{'gi'});

        for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
            my $q_id = "q".$i;
            if (not exists $rpkm{$samples{$q_id}}) {
               $rpkm{$samples{$q_id}} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            }
            $sheet_anno->write( $line_anno, 3+$i, $isoform_list{$acc_id}{$samples{$q_id}});
            if ($isoform_list{$acc_id}{$samples{$q_id}} == 0) {
                $rpkm{$samples{$q_id}}->[0]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 10) {
                $rpkm{$samples{$q_id}}->[1]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 20) {
                $rpkm{$samples{$q_id}}->[2]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 30) {
                $rpkm{$samples{$q_id}}->[3]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 40) {
                $rpkm{$samples{$q_id}}->[4]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 50) {
                $rpkm{$samples{$q_id}}->[5]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 60) {
                $rpkm{$samples{$q_id}}->[6]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 70) {
                $rpkm{$samples{$q_id}}->[7]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 80) {
                $rpkm{$samples{$q_id}}->[8]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 90) {
                $rpkm{$samples{$q_id}}->[9]++;
            }
            elsif ($isoform_list{$acc_id}{$samples{$q_id}} <= 100) {
                $rpkm{$samples{$q_id}}->[10]++;
            }
            else {
                $rpkm{$samples{$q_id}}->[11]++;
            }
        }
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
        $sheet_anno->write ($line_anno,  5+$#seq_files+$pair_count, $isoform_list{$acc_id}{'desc'});
        $sheet_anno->write ($line_anno,  6+$#seq_files+$pair_count, $isoform_list{$acc_id}{'go_desc'});
#        if ($p_value_ok == 1) {
#            $sheet_diff->write ($line_diff,  5+$#seq_files+$pair_count, $isoform_list{$acc_id}{'desc'});
#            $sheet_diff->write ($line_diff,  6+$#seq_files+$pair_count, $isoform_list{$acc_id}{'go_desc'});
#            $line_diff++;
#        }
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
            for (my $i = 0 ; $i <= $#seq_files; $i++) {
                my $seq = $seq_files[$i];
                $seq =~ s/\..+//;
                $seq =~ s/ //g;
                if (exists $all_go{$level1}{$level2}{$seq}) {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_head_go);
                    $sheet_gote->write($line_summ, 2+$samples_number, $all_go{$level1}{$level2}{$seq} );
                }
                else {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_head_go);
                    $sheet_gote->write($line_summ, 2+$samples_number, "0");
                }
                $samples_number++;
            }
            $line_summ++;
        }
    }
    my $lines_of_gote = $line_summ--;
    $columns_of_gote = "B";
    my $chart = $excel_dist->add_chart( type => 'column', embedded => 1 );

    $line_summ = 1;
    my $line_id = 3;
    foreach my $sample_name (keys %rpkm) {
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
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end", $num_format);
            }
            elsif ($i <= 10) {
                my $range = $i * 10;
                my $range1 = $range - 10;
                $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format_rpkm );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val");
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end", $num_format);
            }
            elsif ($i == 11) {
                $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format_rpkm );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val", );
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

    if ($pnt eq "yes") {
        my $input_reference = Bio::SeqIO->new(-file => "$ref.fa",-format => 'Fasta');
        my $output_reference = Bio::SeqIO->new(-file => ">new_transcript.fa",-format => 'Fasta');
        while (my $seqobj = $input_reference->next_seq()) {
            foreach my $new_seq_trans_id (keys %transcriptome) {
                my ($chr, $pos) = split(/:/, $transcriptome{$new_seq_trans_id}{'chr'});
                if ($chr ne $seqobj->id()) {
                    next;
                }
                my ($start_pos, $stop_pos) = split(/-/, $pos);
                my $seqobj_out = Bio::PrimarySeq->new ( -seq => $seqobj->subseq($start_pos, $stop_pos), -id  => $new_seq_trans_id, -alphabet => 'dna');
                $output_reference->write_seq($seqobj_out);
            }
        }
        system("blastall -p blastn -d /share/data/database/NT/nt -e 1e-5 -a 16 -b 10 -m 9 -i new_transcript.fa -o new2nt.blastn");
        system("blastall -p blastx -d /share/data/database/Uniprot/uniprot_sprot.fasta -e 1e-5 -a 16 -b 10 -m 9 -i new_transcript.fa -o new2sw.blastx");
        my $dbh1 = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
        open (NTB, "new2nt.blastn") or die $!;
        while (my $blast_lines = <NTB>) {
            if ($blast_lines =~ /^# Fields: Query/) {
                $blast_lines = <NTB>;
                last unless $blast_lines;
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
    
        my $excel_newt = Excel::Writer::XLSX -> new ( "New_Transcript.xlsx" );
        my $sheet_newt = $excel_newt->add_worksheet( "New_Transcript_anno" );
        my $newt_head = $excel_newt->add_format( fg_color => 0x30, align => 'center', bold => 1);
        $sheet_newt->write( 0, 0, "Transcript_ID", $my_head );
        $sheet_newt->write( 0, 1, "Gene_Name", $my_head );
        $sheet_newt->set_column( 'A:A', 18 );
        $sheet_newt->set_column( 'B:B', 12 );
    
        $columns_of_gote = "C";
        for (my $i = 0 ; $i <= $#seq_files; $i++) {
            my $seq = $seq_files[$i];
            $seq =~ s/\..+//;
            $seq =~ s/ //g;
            $sheet_newt->write( 0, 2+$i, "RPKM_$seq", $my_head );
            $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 15 );
            $columns_of_gote++;
        }
        $pair_count = 0;
        foreach (keys %pair_id_list) {
            $sheet_newt->write( 0, 3+$#seq_files+$pair_count, "q-Value_$_", $my_head );
            $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 25 );
            $columns_of_gote++;
            $pair_count++;
        }
        
        $sheet_newt->write( 0, 3 + $#seq_files + $pair_count, "Best_Hit_to_NT_ID", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 40 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 4 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_ID", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 30 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 5 + $#seq_files + $pair_count, "Best_Hit_to_NT_Evalue", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 6 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Evalue", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 10 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 7 + $#seq_files + $pair_count, "Best_Hit_to_NT_Desc", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $columns_of_gote++;
        $sheet_newt->write( 0, 8 + $#seq_files + $pair_count, "Best_Hit_to_SwissProt_Desc", $my_head );
        $sheet_newt->set_column( "$columns_of_gote:$columns_of_gote", 60 );
        $columns_of_gote++;
    
        $line_anno = 0;
        foreach my $acc_id (keys %transcriptome) {
            $line_anno++;
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
        my $sheet_diff = $excel_diff->add_worksheet( "Diff_Express_Gene" );
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
        my %go_sample;
       
        my $sheet = shift @{$excel_read -> {Worksheet}};
        $sheet -> {MaxRow} ||= $sheet -> {MinRow};
        $sheet -> {MaxCol} ||= $sheet -> {MinCol};
        my $max_col = $sheet -> {MaxCol};
        my ($col_read1, $col_read2, $col_p) = (0, 0, 0);
        foreach my $col (4 ..  $sheet -> {MaxCol}) {
            my $cell = $sheet -> {Cells} [0] [$col];
            if ($diff_sample1 =~ /$cell->{Val}/) {
                $col_read1 = $col;
                $sheet_diff->write( 0, 4, "RPKM_$diff_sample1", $my_head_diff );
            }
            elsif ($diff_sample2 =~ /$cell->{Val}/) {
                $col_read2 = $col;
                $sheet_diff->write( 0, 5, "RPKM_$diff_sample2", $my_head_diff );
            }
            elsif ($pair_diff =~ /$cell->{Val}/) {
                $col_p = $col;
            }
        }
        $sheet_diff->write( 0, 6, "RPKM_Ratio", $my_head_diff );
        $sheet_diff->write( 0, 7, "q-Value", $my_head_diff );
        $sheet_diff->write( 0, 8, "Description", $my_head_diff );
        $sheet_diff->write( 0, 9, "Gene_Ontology", $my_head_diff );
        if ($col_read1 == 0 || $col_read2 == 0 || $col_p == 0) {
             die "Read col err!\n";
        }

        foreach my $row ( 1 .. $sheet -> {MaxRow}) {
             my $cell = $sheet -> {Cells} [$row] [$col_p];
             my $q_val = $cell->{Val};
             if ($q_val < 0.01) {
                 $cell = $sheet -> {Cells} [$row] [$max_col];
                 my @row = split(/, /, $$cell->{Val});
                 for (my $i = 0; $i<4; $i++) {
                     $cell = $sheet -> {Cells} [$row] [$i];
                     $sheet_diff->write( $wirte_row, $i, $cell->{Val}); 
                 }
                 $cell = $sheet -> {Cells} [$row] [$col_read1];
                 my $rpkm_1 = $cell->{Val};
                 $sheet_diff->write( $wirte_row, 4, $cell->{Val});
                 $cell = $sheet -> {Cells} [$row] [$col_read2];
                 my $rpkm_2 = $cell->{Val};
                 $sheet_diff->write( $wirte_row, 5, $cell->{Val});
                 $cell = $sheet -> {Cells} [$row] [$col_p];
                 if ($rpkm_1 != 0 && $rpkm_2 != 0 && $rpkm_1 > $rpkm_2) {
                     $sheet_diff->write( $wirte_row, 6, sprintf('5.2%f', $rpkm_1/$rpkm_2));
                 }
                 elsif ($rpkm_1 != 0 && $rpkm_2 != 0 && $rpkm_1 < $rpkm_2) {
                     $sheet_diff->write( $wirte_row, 6, sprintf('5.2%f', $rpkm_2/$rpkm_1));
                 }
                 else {
                     $sheet_diff->write( $wirte_row, 6, sprintf('5.2%f', "NULL"));
                 }
                 $sheet_diff->write( $wirte_row, 7, $q_val);
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
         $wirte_row = 2;
         foreach my $level1 (keys %go_sample) {
             $sheet_godi->write($wirte_row, 0, $level1, $my_format_godi );
             foreach my $level2 (keys %{$all_go{$level1}}) {
                 $sheet_godi->write($wirte_row, 1, $level2, $my_format_godi );
                 if (exists $all_go{$level1}{$level2}{'s1'}) {
                     $sheet_godi->write($wirte_row, 2, $all_go{$level1}{$level2}{'s1'} );
                 }
                 else {
                     $sheet_godi->write($wirte_row, 2, "0");
                 }
                 if (exists $all_go{$level1}{$level2}{'s2'}) {
                     $sheet_godi->write($wirte_row, 3, $all_go{$level1}{$level2}{'s2'} );
                 }
                 else {
                     $sheet_godi->write($wirte_row, 3, "0");
                 }
                 $wirte_row++;
             }
         }
        $wirte_row--;
        my $chart_godi = $excel_godi->add_chart( type => 'column', embedded => 1 );
        $chart_godi->add_series(
            name       => "=Gene_Ontology!\$C\$2",
            categories => "=Gene_Ontology!\$A\$3:\$B\$$wirte_row",
            values     => "=Gene_Ontology!\$C\$3:\$C\$$wirte_row",
        );
        $chart_godi->add_series(
            name       => "=Gene_Ontology!\$D\$2",
            categories => "=Gene_Ontology!\$A\$3:\$B\$$wirte_row",
            values     => "=Gene_Ontology!\$D\$3:\$D\$$wirte_row",
        );
        $chart_godi->set_title ( name => 'GO Distribution' );
        $chart_godi->set_x_axis( name => "Catalogue" );
        $chart_godi->set_y_axis( name => 'Number' );
        $chart_godi->set_style( 21 );
        $sheet_godi->insert_chart( "A$wirte_row", $chart_godi, 0, 0, 2.5, 3 ); 
    }
}
