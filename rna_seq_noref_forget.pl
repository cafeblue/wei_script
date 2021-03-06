#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use warnings;

use Getopt::Long;
#use PerlIO::gzip;
#use threads;
use DBI();
use Excel::Writer::XLSX;

##################################################
# Example of config.txt file:
#
# $ cat config.txt
#
# [lib_se]
# q=./sample1.fq
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
# [nt]
# NT=/home/wangw/workdir/genome/bowtie/hg19.fa
#
# [nr]
# NR=31
#
# [swissprot]
# GTF=/home/wangw/workdir/R1_t-t9/refGene_my.gtf
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
$config_file = $opts{s} unless $opts{"p"};
open (CONF, "$config_file") or die $usage;
my @seq_files;
my @seq_files2 = ();
my @insertsize = ();
my $ref;
my $gtf;

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
}

system ("VelvetOptimiser.pl --s 43 --t 2 --d final_velvet --o \'-ins_length $ins\' --f \'-fastq -shortPaired $shuffle\'");

my $dbh = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";

#while my $seq_name (@seq_files) {
if ($#seq_files == 0) {
    my $seq_name = pop(@seq_files);
    my $seq = $seq_name;
    $seq =~ s/\..+//;
    $seq =~ s/ //g;
    my $seq_name2;
    my $ins;
    if ($#insertsize > -1) {
        $seq_name2 = pop(@seq_files2);
        $ins = pop(@insertsize);
        system("tophat -o tophat_$seq  -r $ins --solexa-quals -p 16 -G $gtf $ref $seq_name $seq_name2");
        system("cufflinks -o cufflinks_$seq -p 16 -G $gtf ./tophat_$seq/accepted_hits.bam");
    }
    else {
        system("tophat -o tophat_$seq --solexa1.3-quals -p 16 -G $gtf $ref $seq_name");
        system("cufflinks --no-update-check -o cufflinks_$seq -p 16 -G $gtf ./tophat_$seq/accepted_hits.bam");
    }
    my %all_go;
    my @rpkm = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    my $excel = Excel::Writer::XLSX -> new ( "$seq.xlsx" );
    my $sheet_anno = $excel->add_worksheet( "RPKM" );
    my $sheet_summ = $excel->add_worksheet( "Summary" );
    my $sheet_gote = $excel->add_worksheet( "Gene_Ontology" );
    my $my_head = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1, center_across => 1);
    my $my_format = $excel->add_format( fg_color => 0x2C, align => 'center');

    $sheet_anno->write( 0, 0, "Chromosome", $my_head );
    $sheet_anno->write( 0, 1, "Accession_Num", $my_head );
    $sheet_anno->write( 0, 2, "GI", $my_head );
    $sheet_anno->write( 0, 3, "Exon_Length", $my_head );
    $sheet_anno->write( 0, 4, "RPKM", $my_head );
    $sheet_anno->write( 0, 5, "Description", $my_head );
    $sheet_anno->write( 0, 6, "Gene_Ontology", $my_head );
    my $line_anno = 0;

    $sheet_summ->write( 0, 0, "RPKM Destribution", $my_merge );
    $sheet_summ->write_blank( 0, 1,  $my_merge );
    $sheet_summ->write_blank( 0, 2,  $my_merge );
    $sheet_summ->write( 1, 0, "Range", $my_head );
    $sheet_summ->write( 1, 1, "Number", $my_head );
    $sheet_summ->write( 1, 2, "Ratio", $my_head );

    $sheet_gote->write( 0, 0, "GO Ontology", $my_merge);
    $sheet_gote->write_blank( 0, 1,  $my_merge );
    $sheet_gote->write_blank( 0, 2,  $my_merge );
    $sheet_gote->write( 1, 0, "Type", $my_head );
    $sheet_gote->write( 1, 1, "Level3 Description", $my_head );
    $sheet_gote->write( 1, 2, "Gene Number", $my_head );
    my $line_summ = 1;

    open (RPKM, "./cufflinks_$seq/isoforms.fpkm_tracking") or die $!;
    my $total_lines = `wc -l ./cuffdiff_all/isoform_exp.diff`;
    chomp($total_lines);
    $total_lines =~ s/\s.+//;
    my $line = <RPKM>;
    while (<RPKM>) {
        $line_anno++;
        my @lines = split(/\t/, $_);
        my $sth = $dbh->prepare("SELECT gi FROM gene_annotation.gi2accession WHERE accession = \'$lines[0]\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        my $gi = pop(@row);
        $sth = $dbh->prepare("SELECT description FROM gene_annotation.gi2description WHERE gi = \'$gi\'");
        $sth->execute();
        @row = $sth->fetchrow_array ;
        my $desc = pop(@row);
        $sth = $dbh->prepare("SELECT goid FROM gene_annotation.gi2go WHERE gi = \'$gi\'");
        $sth->execute();
        @row = ();
        my $rows_ref = $sth->fetchall_arrayref ;
        while (my $row = pop(@$rows_ref)) {
            push @row, @$row;
        }
        foreach my $go_id (@row) {
            $sth = $dbh->prepare("select term_type,description from gene_annotation.level2desc where go = \'$go_id\'");
            $sth->execute();
#            my @row_type = $sth->fetchall_arrayref ;
#            my @row_go = $sth->fetchrow_array ;
            my $rows_ref = $sth->fetchall_arrayref;
#            foreach my $go_desc (@row_go) {
            while (my $row = pop(@$rows_ref)) {
                if (exists $all_go{${$row}[0]}{${$row}[1]}) {
                    $all_go{${$row}[0]}{${$row}[1]}++;
                }
                else {
                    $all_go{${$row}[0]}{${$row}[1]} = 1;
                }
            }

        }
        my $go_desc = join('; ', @row);

        $sheet_anno->write ( $line_anno, 0, "$lines[6]" , $my_format);
        $sheet_anno->write ( $line_anno, 1, "$lines[0]" , $my_format);
        $sheet_anno->write ( $line_anno, 2, "\=HYPERLINK\(\"http\:\/\/www\.ncbi\.nlm\.nih\.gov\/gene\?term\=$gi\",\"$gi\"\)" , $my_format);
        $sheet_anno->write ( $line_anno, 3, "$lines[7]" , $my_format);
        $sheet_anno->write ( $line_anno, 4, "$lines[10]" , $my_format);
        $sheet_anno->write ( $line_anno, 5, "$desc" , $my_format);
        $sheet_anno->write ( $line_anno, 6, "$go_desc" , $my_format);

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
        print "$. of $total_lines ...  ";
        my $percent = sprintf('%5.2f', $./$total_lines);
        print $percent,'%', "\cM";
    }

    $line_summ++;
    foreach my $level1 (keys %all_go) {
        $sheet_gote->write($line_summ, 0, $level1, $my_format );
        foreach my $level2 (keys %{$all_go{$level1}}) {
            $sheet_gote->write($line_summ, 1, $level2, $my_format );;
            $sheet_gote->write($line_summ, 2, $all_go{$level1}{$level2}, $my_format );
            $line_summ++;
        }
        $line_summ++;
    }

    my $lines_of_gote = $line_summ--;
    $lines_of_gote--;
    $line_summ = 1;
    foreach my $rpkm_val (shift(@rpkm)) {
        $line_summ++;
        if ($line_summ == 2) {
            $sheet_summ->write( $line_summ, 0, "0", $my_format );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
            $sheet_summ->write( $line_summ, 2, '=B3/B15*100', $my_format );
        }
        elsif ($line_summ <= 12) {
            my $range = ($line_summ - 2) * 10;
            my $range1 = $range - 10;
            my $line_id = $line_summ + 1;
            $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
            $sheet_summ->write( $line_summ, 2, "=B$line_id/B15*100", $my_format );
        }
        elsif ($line_summ == 13) {
            $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format );
            $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
            $sheet_summ->write( $line_summ, 2, "=B14/B15*100", $my_format );
        }
        else {
            die "Something Wrong\?\n";
        }
    }
    $sheet_summ->write( 14, 0, "Total:", $my_format );
    $sheet_summ->write( 14, 1, "=SUM(B3:B14)", $my_format );
    $sheet_summ->write( 14, 2, "=SUM(C3:C14)", $my_format );
    my $chart = $excel->add_chart( type => 'column', embedded => 1 );
    
    $chart->add_series(
        name       => "$seq",
        categories => '=Summary!$A$3:$A$14',
        values     => '=Summary!$B$3:$B$14',
    );
    
    $chart->set_title ( name => 'RPKM Distribution' );
    $chart->set_x_axis( name => 'Number' );
    $chart->set_y_axis( name => 'RPKM Range' );
    
    # Set an Excel chart style. Blue colors with white outline and shadow.
    $chart->set_style( 11 );
    
    # Insert the chart into the worksheet (with an offset).
    $sheet_summ->insert_chart( 'D2', $chart, 60, 40 ); 

    my $chart_go = $excel->add_chart( type => 'column', embedded => 1 );
    $chart_go->add_series(
        name       => "$seq",
        categories => "=Gene_Ontology!\$B\$3:\$B\$$lines_of_gote",
        values     => "=Gene_Ontology!\$C\$3:\$C\$$lines_of_gote",
    );
    
    $chart_go->set_title ( name => 'GO Level3 Distribution' );
    $chart_go->set_x_axis( name => 'Level3 Type' );
    $chart_go->set_y_axis( name => 'Number' );
    $chart_go->set_style( 11 );
    $sheet_gote->insert_chart( 'D2', $chart_go, 60, 40 ); 
}

else {
    my $all_bamfiles = "";
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
        if ($#insertsize > -1) {
            system("tophat -o tophat_$seq -r $insertsize[$i] --solexa-quals -p 16 -G $gtf $ref $seq_files[$i] $seq_files2[$i]");
            $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
        }
        else {
            system("tophat -o tophat_$seq --solexa1.3-quals -p 16 -G $gtf $ref $seq_files[$i]");
            $all_bamfiles .= " tophat_$seq/accepted_hits.bam";
        }
    }
    system("cuffdiff --no-update-check -p 16 -o cuffdiff_all $gtf $all_bamfiles");

    my $excel = Excel::Writer::XLSX -> new ( "Reports.xlsx" );
#    open (WEGO, ">$seq.wego") or die $!;
    my $sheet_anno = $excel->add_worksheet( "RPKM" );
    my $sheet_summ = $excel->add_worksheet( "Summary" );
    my $sheet_gote = $excel->add_worksheet( "Gene_Ontology" );
    my $my_head = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1);
    my $my_merge = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1, center_across => 1);
    my $my_format = $excel->add_format( fg_color => 0x2C, align => 'center');

    $sheet_gote->write( 0, 0, "GO Ontology", $my_merge);
    $sheet_gote->write_blank( 0, 1,  $my_merge );
    $sheet_gote->write_blank( 0, 2,  $my_merge );
    $sheet_gote->write( 1, 0, "Type", $my_head );
    $sheet_gote->write( 1, 1, "Level3 Description", $my_head );
    my $line_summ = 1;
###  select name from gene_annotation.term where id in (select term1_id from (select (B.distance - 2) as DIST, A.id from (select id from gene_annotation.term where acc = 'GO:0002790') A, gene_annotation.graph_path B where B.term2_id = A.id  and B.term1_id = '34658') A, gene_annotation.graph_path B where B.term2_id = A.id and B.distance = A.DIST ) and id in (select term2_id from gene_annotation.graph_path where term1_id = '34658' and distance = '2' and relation_distance = '2');
    open (RPKM, "./cuffdiff_all/isoform_exp.diff") or die $!;
    my $total_lines = `wc -l ./cuffdiff_all/isoform_exp.diff`;
    chomp($total_lines);
    $total_lines =~ s/\s.+//;
    my $line = <RPKM>;
    my %pair_id_list;
    while (<RPKM>) {
        my @lines = split(/\t/, $_);
        my $sth = $dbh->prepare("SELECT gi FROM gene_annotation.gi2accession WHERE accession = \'$lines[0]\'");
        $sth->execute();
        my @row = $sth->fetchrow_array ;
        my $gi = pop(@row);
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
#        my $go_desc = join('; ', @row);
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
        $isoform_list{"$lines[0]"}{'chr'} = $lines[3];
        $isoform_list{"$lines[0]"}{'acc'} = $lines[0];
        $isoform_list{"$lines[0]"}{$samples{$lines[4]}} = $lines[7];
        $isoform_list{"$lines[0]"}{$samples{$lines[5]}} = $lines[8];
        my $pair_id = $samples{$lines[4]}."_to_".$samples{$lines[5]};
        $isoform_list{"$lines[0]"}{$pair_id} = $lines[11];
        if (not exists $pair_id_list{$pair_id}) {
            $pair_id_list{$pair_id} = 1;
        }
        $isoform_list{"$lines[0]"}{'gi'} = "\=HYPERLINK\(\"http\:\/\/www\.ncbi\.nlm\.nih\.gov\/gene\?term\=$gi\",\"$gi\"\)";
        $isoform_list{"$lines[0]"}{'desc'} = $desc;
        print "$.\tof $total_lines ...  \t", sprintf ('%5.2f', $./$total_lines*100), "%\cM";
    }

    $sheet_anno->write( 0, 0, "Chromosome", $my_head );
    $sheet_anno->write( 0, 1, "Accession_Num", $my_head );
    $sheet_anno->write( 0, 2, "GI", $my_head );
    for (my $i = 0 ; $i <= $#seq_files; $i++) {
        my $seq = $seq_files[$i];
        $seq =~ s/\..+//;
        $seq =~ s/ //g;
        $sheet_anno->write( 0, 3+$i, "RPKM_$seq", $my_head );
    }
    my $pair_count = 0;
    foreach (keys %pair_id_list) {
        $sheet_anno->write( 0, 4+$#seq_files+$pair_count, "pValue_$_", $my_head );
        $pair_count++;
    }
    $sheet_anno->write( 0, 4 + $#seq_files + $pair_count, "Description", $my_head );
    $sheet_anno->write( 0, 5 + $#seq_files + $pair_count, "Gene_Ontology", $my_head );
    my $line_anno = 0;

    foreach my $acc_id (keys %isoform_list) {
        $line_anno++;
        $sheet_anno->write ($line_anno, 0, $isoform_list{$acc_id}{'chr'});
        $sheet_anno->write ($line_anno, 1, $acc_id);
        $sheet_anno->write ($line_anno, 2, $isoform_list{$acc_id}{'gi'});
        for (my $i = 1 ; $i <= $#seq_files+1; $i++) {
            my $q_id = "q".$i;
            if (not exists $rpkm{$samples{$q_id}}) {
               $rpkm{$samples{$q_id}} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            }
            $sheet_anno->write( $line_anno, 2+$i, $isoform_list{$acc_id}{$samples{$q_id}});
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
        foreach my $pair_id (keys %pair_id_list) {
            $sheet_anno->write( $line_anno, 4+$#seq_files+$pair_count, $isoform_list{$acc_id}{$pair_id});
            $pair_count++;
        }
        $sheet_anno->write ($line_anno,  4+$#seq_files+$pair_count, $isoform_list{$acc_id}{'desc'});
        $sheet_anno->write ($line_anno,  5+$#seq_files+$pair_count, $isoform_list{$acc_id}{'go_desc'});
    }

    $line_anno = 0;
    $sheet_summ->write( 0, 0, "RPKM Destribution", $my_merge );
    $sheet_summ->write_blank( 0, 1,  $my_merge );
    $sheet_summ->write_blank( 0, 2,  $my_merge );
    $sheet_summ->write( 1, 0, "Range", $my_head );
    $sheet_summ->write( 1, 1, "Number", $my_head );
    $sheet_summ->write( 1, 2, "Ratio", $my_head );

    $line_summ++;
    foreach my $level1 (keys %all_go) {
        $sheet_gote->write($line_summ, 0, $level1, $my_format );
        foreach my $level2 (keys %{$all_go{$level1}}) {
            $sheet_gote->write($line_summ, 1, $level2, $my_format );
            my $samples_number = 0;
            for (my $i = 0 ; $i <= $#seq_files; $i++) {
                my $seq = $seq_files[$i];
                $seq =~ s/\..+//;
                $seq =~ s/ //g;
                if (exists $all_go{$level1}{$level2}{$seq}) {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_format);
                    $sheet_gote->write($line_summ, 2+$samples_number, $all_go{$level1}{$level2}{$seq} );
                }
                else {
                    $sheet_gote->write(1, 2+$samples_number, $seq, $my_format);
                    $sheet_gote->write($line_summ, 2+$samples_number, "0");
                }
                $samples_number++;
            }
            $line_summ++;
        }
        $line_summ++;
    }
    my $lines_of_gote = $line_summ--;
    my $columns_of_gote = "B";
    my $chart = $excel->add_chart( type => 'column', embedded => 1 );

    $line_summ = 1;
    my $line_id = 3;
    foreach my $sample_name (keys %rpkm) {
        $line_summ++;
        $sheet_summ->write( $line_summ, 0, "$sample_name", $my_format );
        my $sample_end;
        for (my $i = 0; $i <= 11; $i++ ) {
#        foreach my $rpkm_val (shift(@{$rpkm{$sample_name}})) {
            my $rpkm_val = ${$rpkm{$sample_name}}[$i];
            $line_summ++;
            $line_id = $line_summ + 1;
            if ($i == 0) {
                $sample_end = $line_id+11;
                $sheet_summ->write( $line_summ, 0, "0", $my_format );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end*100", $my_format );
            }
            elsif ($i <= 10) {
                my $range = $i * 10;
                my $range1 = $range - 10;
                $sheet_summ->write( $line_summ, 0, "$range1 -- $range", $my_format );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end*100", $my_format );
            }
            elsif ($i == 11) {
                $sheet_summ->write( $line_summ, 0, "100 -- ", $my_format );
                $sheet_summ->write( $line_summ, 1, "$rpkm_val", $my_format );
                $sheet_summ->write( $line_summ, 2, "=B$line_id/B$sample_end*100", $my_format );
            }
        }
        my $sample_start = $sample_end - 11;
        $chart->add_series(
            name       => "$sample_name",
            categories => "=Summary!\$A\$$sample_start:\$A\$$sample_end",
            values     => "=Summary!\$B\$$sample_start:\$B\$$sample_end",
        );
        $line_summ++;
        $sheet_summ->write( $line_summ, 0, "Total:", $my_format );
        $sheet_summ->write( $line_summ, 1, "=SUM(B$sample_start:B$sample_end", $my_format );
        $sheet_summ->write( $line_summ, 2, "100", $my_format );
        $line_summ++;
    }
    $chart->set_title ( name => 'RPKM Distribution' );
    $chart->set_x_axis( name => 'Number' );
    $chart->set_y_axis( name => 'RPKM Range' );
    $chart->set_style( 10 );

    $sheet_summ->insert_chart( 'B2', $chart, 120, 80 ); 
    my $chart_go = $excel->add_chart( type => 'column', embedded => 1 );
    for (my $i = 0; $i <= $#seq_files; $i++) {
        $columns_of_gote++;
        $chart_go->add_series(
            name       => "=Gene_Ontology!\$$columns_of_gote\$2",
            categories => "=Gene_Ontology!\$B\$3:\$B\$$lines_of_gote",
            values     => "=Gene_Ontology!\$$columns_of_gote\$3:\$C\$$lines_of_gote",
        );
    }
    
    $chart_go->set_title ( name => 'GO Level3 Distribution' );
    $chart_go->set_x_axis( name => 'Level3 Type' );
    $chart_go->set_y_axis( name => 'Number' );
    $chart_go->set_style( 10 );
    $sheet_gote->insert_chart( 'B3', $chart_go, 120, 80 ); 

}
