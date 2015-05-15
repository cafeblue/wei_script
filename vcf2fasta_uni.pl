#! /bin/env perl

use strict;
use Bio::SeqIO;
use Getopt::Long qw(:config no_ignore_case);
my @out_twelve;
my @sample_list;

my %opts;
GetOptions(\%opts, "v:s", "o:s", "l:s", "m:i", "d:i", "C:i", "D:i", "i:i", "g:i", "a:s");
my $usage = <<USAGE;

    Program: $0
    Version: 0.4
    Contact: Wei Wang(oneway.wang\@utoronto.ca)

    Usage:   $0 -v vcf_file -o output_folder -l logfile [-m [num] -d [num] -D [num] -C [num] -i [num] -g [num] -a T/F]

                -v input vcf file
                -o folder to put the fasta files;
                -l log file
                -m cutoff for mapping quality ( column 6 in vcf file) [60]
                -i number of bps around the indel set as "N". [5]
                -C max depth of all individual to set as "N". [10000]
                -d min depth of each individual to set as "N". [20]
                -D max depth of each individual to set as "N". [2500]
                -g GQ of each individual to set as "N". [60]
                -a output each site (not CDS region only) [F]

    Example: $0 -v ../ouput.vcf -o ./fasta_folder -l log.txt
             $0 -v output.vcf -o fasta_folder -l log.txt -m 20 -d 5 -i 2 -g 20 -a T

USAGE
# add parameters for the low quality cutoff.

die $usage unless ($opts{v} && $opts{o} && $opts{l});

my $mq_u = 60;
my $id_u = 5;
my $dp_u = 20;
my $dp_U = 2500;
my $dp_C = 10000;
my $gq_u = 60;
my $as_u = "F";
if ($opts{m}) {
    $mq_u = $opts{m};
}
if ($opts{d}) {
    $dp_u = $opts{d};
}
if ($opts{D}) {
    $dp_U = $opts{D};
}
if ($opts{C}) {
    $dp_C = $opts{C};
}
if ($opts{i}) {
    $id_u = $opts{i};
}
if ($opts{g}) {
    $gq_u = $opts{g};
}
if ($opts{a}) {
    $as_u = $opts{a};
}

open (VCF, "$opts{v}") or die $!;
system("mkdir $opts{o}");
open (LOG, ">$opts{l}") or die $!;
my @indels = ();
my $now_pos = 0;
my $lastID = "";
my ($start, $stopp) = (0, 0);
my $position01 = 0;

#output_folderput all sites
if ($opts{a} eq "T" || $opts{a} eq "t") {
    while (<VCF>) {
        if (/^\#/) {
#            if (/^\#\#UnifiedGenotyper.+input_file\=\[(.+?)\]/){
            if (/^#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t(.+)$/){
                chomp($1);
                @sample_list = split(/\t/, $1);
                for (0..$#sample_list) {
                    push @out_twelve, "";
                    push @out_twelve, "";
                }
            }
            next;
        }
        chomp;
        my @line_ele = split(/\t/, $_);
        my $id = $line_ele[0];
        if ($lastID ne "" && $lastID ne $id) {
            $now_pos = 0;
            if ($out_twelve[0] eq "") {
                print STDERR "No CDS in $lastID \n";
            }
            else {
                if ($#indels > -1) {
                    replace_N5(\@out_twelve, \@indels);
                }
                my $out_file_name = (split(/\//, $lastID))[0];
                if ($position01 > 0) {
                    print LOG $out_file_name,"\t",$position01,"\n";
                }
                my $show_length = $stopp - $start + 1;
                my $out_file = Bio::SeqIO->new( -file => ">$opts{o}/$out_file_name.fasta", -format => "fasta");
                for (0..$#sample_list) {
                    my $real_length = length($out_twelve[2*$_]);
                    my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
                    $out_file->write_seq($seq_obj);
                    $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_2_length_$real_length", -seq => $out_twelve[2*$_+1] );
                    $out_file->write_seq($seq_obj);
                    $out_twelve[2*$_] = "";
                    $out_twelve[2*$_+1] = "";
                }
                @indels = ();
            }
            $position01 = 0;
        }
        $lastID = $id;
        my @snp = split(/\,/, $line_ele[4]);

        if (($line_ele[1] - $now_pos) == 0) {
            next;
        }
        elsif (($line_ele[1] - $now_pos) > 1) {
            print STDERR "bases missed between $now_pos and $line_ele[1] at line $. of $id, missed postions replaced by N. \n";
            for ($now_pos+1 .. $line_ele[1]-1) {
                add_oneN(\@out_twelve);
            }
        }
        elsif ($line_ele[1] < $now_pos) {
            die "There is something wrong with the VCF file in line $. ?\n";
        }
        $now_pos = $line_ele[1];

        my $indel_check = 0;
        for (0..$#snp) {
            if (length($snp[$_]) > 1 || length($line_ele[3]) > 1) {
                push @indels, $line_ele[1];
                $indel_check++;
            }
            last if ($indel_check > 0);
        }
        if ($indel_check > 0) {
            add_oneN(\@out_twelve);
            next;
        }

        ####check total Depth start.
        my $total_depth = $line_ele[7] =~ /DP=(\d+);/ ? $1 : 0; 
        die "no \"DP=\" found in line $." if ($total_depth == 0);
        if ($total_depth > $dp_C) {
            add_oneN(\@out_twelve);
            next;
        }
        ####check total Depth end.

        if ($line_ele[5] < $mq_u && $line_ele[5] ne '.') {
            add_oneN(\@out_twelve);
            next;
        }

        # Do NOT ignore the non-variant sites, 
        #if ($snp[0] eq '.') {
        #    add_refB(\@out_twelve, $line_ele[3]);
        #    next;
        #}

        my @flags = split(/\:/, $line_ele[8]);
        my $dp_pos = 20;
        my $gq_pos = 20;
        for (0..$#flags) {
            if ($flags[$_] eq "DP") {
                $dp_pos = $_;
            }
            elsif ($flags[$_] eq "GQ") {
                $gq_pos = $_;
            }
        }
        #  All position swithch could not garantee all the GP, GT, DP and GQ.
        #if ($dp_pos == 0 || $gq_pos == 0) {
        #    die "DP or GQ in the first position\t $line_ele[8]\n";
        #}
        my $count01 = 0;
        for (my $i = $#sample_list; $i>-1; $i--) {
            my $now_id = pop(@line_ele);
            my ($gt, $dp, $gq) = (10000, 10000, 10000);
            $gt = (split(/\:/, $now_id))[0];
            #print "$i\t at pos: ",$line_ele[1],"\t",$gt,"\n";
            if ($dp_pos != 20) {
                $dp = (split(/\:/, $now_id))[$dp_pos];
            }
            if ($gq_pos != 20) {
                $gq = (split(/\:/, $now_id))[$gq_pos];
            }

            if ($dp < $dp_u || $dp > $dp_U || $gq < $gq_u){
                $out_twelve[2*$i] .= "N";
                $out_twelve[2*$i+1] .= "N";
            }
            elsif ($gt eq '0/0' || $gt eq '10000') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $line_ele[3];
            }
            elsif ($gt eq '0/1') {
                $count01++;
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[0];
            }
            elsif ($gt eq '0/2') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '0/3') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '1/1') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[0];
            }
            elsif ($gt eq '1/2') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '1/3') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '2/2') {
                $out_twelve[2*$i] .= $snp[1];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '2/3') {
                $out_twelve[2*$i] .= $snp[1];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '3/3') {
                $out_twelve[2*$i] .= $snp[2];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            else {
                die "$gt is abnormal on line $. ?\n"
            }
        }
        if ($count01 == $#sample_list - 1) {
            $position01++;
        }
    }
    if ($#indels > -1) {
        replace_N5(\@out_twelve, \@indels);
    }
    my $out_file_name = (split(/\//, $lastID))[0];
        if ($position01 > 0) {
            print LOG $out_file_name,"\t",$position01,"\n";
        }
    my $out_file = Bio::SeqIO->new( -file => ">$opts{o}/$out_file_name.fasta", -format => "fasta");
    for (0..$#sample_list) {
        my $real_length = length($out_twelve[2*$_]);
        my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
        $out_file->write_seq($seq_obj);
        $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_2_length_$real_length", -seq => $out_twelve[2*$_+1] );
        $out_file->write_seq($seq_obj);
    }
}
# output CDS region only
else {
    VCF: while (<VCF>) {
        if (/^\#/) {
#            if (/^\#\#UnifiedGenotyper.+input_file\=\[(.+?)\]/){
            if (/^#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t(.+)$/){
                chomp($1);
                @sample_list = split(/\t/, $1);
                for (0..$#sample_list) {
                    push @out_twelve, "";
                    push @out_twelve, "";
                }
            }
            next;
        }
        chomp;
        my @line_ele = split(/\t/, $_);
        my $id = $line_ele[0];
        if ($lastID ne "" && $lastID ne $id) {
            $now_pos = 0;
            if ($out_twelve[0] eq "") {
                print STDERR "No CDS in $lastID \n";
            }
            else {
                if ($#indels > -1) {
                    replace_N5(\@out_twelve, \@indels);
                }
                my $out_file_name = (split(/\//, $lastID))[0];
                if ($position01 > 0) {
                    print LOG $out_file_name,"\t",$position01,"\n";
                }
                my $show_length = $stopp - $start + 1;
                my $out_file = Bio::SeqIO->new( -file => ">$opts{o}/$out_file_name.fasta", -format => "fasta");
                for (0..$#sample_list) {
                    my $real_length = length($out_twelve[2*$_]);
                    my $show_length = $stopp - $start + 1;
                    if ($real_length != $show_length) {
                        print LOG "CDS boundary falls in the missing! $real_length, $show_length, $out_file_name, $.\n$out_twelve[2*$_]\n";
                        $out_twelve[2*$_] = "";
                        $out_twelve[2*$_+1] = "";
                        next;
                    }
                    my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
                    $out_file->write_seq($seq_obj);
                    $real_length = length($out_twelve[2*$_+1]);
                    if ($real_length != $show_length) {
                        print LOG "CDS boundary falls in the missing!!! $real_length, $show_length, $out_file_name\n";
                        $out_twelve[2*$_] = "";
                        $out_twelve[2*$_+1] = "";
                        next;
                    }
                    $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_2_length_$real_length", -seq => $out_twelve[2*$_+1] );
                    $out_file->write_seq($seq_obj);
                    $out_twelve[2*$_] = "";
                    $out_twelve[2*$_+1] = "";
                }
                @indels = ();
            }
            $position01 = 0;
        }
        $lastID = $id;
        if ($id =~ /__CDS__(\d+)__(\d+)/) {
            $start = $1;
            $stopp = $2;
        }
        else {
            $now_pos = 0;
            next;
        }
        if ($line_ele[1] < $start || $line_ele[1] > $stopp) {
            $now_pos = $line_ele[1];
            next;
        }
        my @snp = split(/\,/, $line_ele[4]);
        for (0..$#snp) {
            if (length($snp[$_]) > 1 || length($line_ele[3]) > 1) {
                $snp[$_] = (split(//, $snp[$_]))[0];
                my $poss = $line_ele[1] - $start + 1;
                push @indels, $poss;
            }
        }
        $line_ele[3] = (split(//, $line_ele[3]))[0];
        if (($line_ele[1] - $now_pos) == 0) {
            next;
        }
        elsif (($line_ele[1] - $now_pos) > 1) {
            if ($line_ele[1] > $start && $now_pos < $start) {
                print STDERR "bases located in CDS region missed between $now_pos and $line_ele[1] at line $. of $id, missed postions replaced by N. \n";
                for ($start .. $line_ele[1]-1) {
                    add_oneN(\@out_twelve);
                }
            }
            elsif ($now_pos >= $start) {
                print STDERR "bases located in CDS region missed between $now_pos and $line_ele[1] at line $. of $id, missed postions replaced by N. \n";
                for ($now_pos+1 .. $line_ele[1]-1) {
                    add_oneN(\@out_twelve);
                }
            }
            elsif ($line_ele[1] == $start) {
            }
            else {
                die "Fuck! Impossible happend!!! \n";
            }
        }
        elsif ($line_ele[1] < $now_pos) {
            die "There is something wrong with the VCF file in line $. ?\n";
        }
        $now_pos = $line_ele[1];
        #if ($line_ele[5] < $mq_u) {
        if ($line_ele[5] < $mq_u && $line_ele[5] ne '.') {
            add_oneN(\@out_twelve);
            next;
        }

        ####check total Depth start.
        my $total_depth = $line_ele[7] =~ /DP=(\d+);/ ? $1 : 0; 
        die "no \"DP=\" found in line $." if ($total_depth == 0);
        if ($total_depth > $dp_C) {
            add_oneN(\@out_twelve);
            next;
        }
        ####check total Depth end.

        # Do NOT ignore the non-variant sites, 
        #if ($snp[0] eq '.') {
        #    add_refB(\@out_twelve, $line_ele[3]);
        #    next;
        #}
        my @flags = split(/\:/, $line_ele[8]);
        my $dp_pos = 0;
        my $gq_pos = 0;
        for (0..$#flags) {
            if ($flags[$_] eq "DP") {
                $dp_pos = $_;
            }
            elsif ($flags[$_] eq "GQ") {
                $gq_pos = $_;
            }
        }
        if ($dp_pos == 0 || $gq_pos == 0) {
            die "DP or GQ in the first position\t $line_ele[8]\n";
        }
        my $count01 = 0;
        for (my $i = $#sample_list; $i>-1; $i--) {
            my $now_id = pop(@line_ele);
            my ($gt, $dp, $gq) = (split(/\:/, $now_id))[0,$dp_pos,$gq_pos];
            if ($dp < $dp_u || $dp > $dp_U || $gq < $gq_u){
                $out_twelve[2*$i] .= "N";
                $out_twelve[2*$i+1] .= "N";
            }
            elsif ($gt eq '0/0') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $line_ele[3];
            }
            elsif ($gt eq '0/1') {
                $count01++;
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[0];
            }
            elsif ($gt eq '0/2') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '0/3') {
                $out_twelve[2*$i] .= $line_ele[3];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '1/1') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[0];
            }
            elsif ($gt eq '1/2') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '1/3') {
                $out_twelve[2*$i] .= $snp[0];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '2/2') {
                $out_twelve[2*$i] .= $snp[1];
                $out_twelve[2*$i+1] .= $snp[1];
            }
            elsif ($gt eq '2/3') {
                $out_twelve[2*$i] .= $snp[1];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            elsif ($gt eq '3/3') {
                $out_twelve[2*$i] .= $snp[2];
                $out_twelve[2*$i+1] .= $snp[2];
            }
            else {
                die "$gt is abnormal on line $. ?\n"
            }
        }
        if ($count01 == $#sample_list - 1) {
            $position01++;
        }
    }
    if ($#indels > -1) {
        replace_N5(\@out_twelve, \@indels);
    }
    my $out_file_name = (split(/\//, $lastID))[0];
        if ($position01 > 0) {
            print LOG $out_file_name,"\t",$position01,"\n";
        }
    my $out_file = Bio::SeqIO->new( -file => ">$opts{o}/$out_file_name.fasta", -format => "fasta");
    for (0..$#sample_list) {
        my $real_length = length($out_twelve[2*$_]);
        my $show_length = $stopp - $start + 1;
        if ($real_length != $show_length) {
            print LOG "CDS boundary falls in the missing Length unequal! $out_file_name\n";
            next;
        }
        my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
        $out_file->write_seq($seq_obj);
        $real_length = length($out_twelve[2*$_+1]);
        if ($real_length != $show_length) {
            print LOG "CDS boundary falls in the missing Length unequal!! $real_length, $show_length, $out_file_name\n";
            next;
        }
        $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_2_length_$real_length", -seq => $out_twelve[2*$_+1] );
        $out_file->write_seq($seq_obj);
    }
}

##   this function is not required any more
##   sub add_refB {
##       my $ref = shift;
##       my $base = shift;
##       for (0..$#$ref) {
##           ${$ref}[$_] .= $base;
##       }
##   }

sub add_oneN {
    my $ref = pop(@_);
    for (0..$#$ref) {
        #foreach my $now_seq (@$ref) {
        #$now_seq .= "N";
        ${$ref}[$_] .= "N";
    }
}

sub replace_N5 {
    my $nam = pop;
    my $pos = pop;
    my $ref = pop;
    foreach my $postion (@$pos) {
        if ($postion < 6) {
            for (0..$#$ref) {
                substr ${$ref}[$_], 0, 5 + $postion, "N" x (5 + $postion);
            }
        }
        elsif ((length(${$ref}[0]) - $postion) < 5) {
            for (0..$#$ref) {
                substr ${$ref}[$_], $postion-6, length(${$ref}[0]) - $postion + 6, "N" x (length(${$ref}[0]) - $postion + 6);
            }
        }
        elsif ((length(${$ref}[0]) < $postion)) {
            die "$postion larger than the sequences?\n";
        }
        else {
            for (0..$#$ref) {
                substr ${$ref}[$_], $postion-6, 11, "N" x 11;
            }
        }
    }
#    if (length(${$ref}[0]) <= 5) {
#        for (0..11) {
#            ${$ref}[$_] =~ s/(A|T|G|C)/N/g;
#        }
#    }
#    else {
#        for (0..11) {
#            ${$ref}[$_] =~ s/\w{5}$/NNNNN/;
#        }
#    }
}
