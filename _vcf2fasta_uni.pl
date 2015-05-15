#! /bin/env perl

use strict;
use Bio::SeqIO;
#use Bio::Seq;
my @out_twelve;
my @sample_list;

my $usage = <<USAGE;

    Program: $0
    Version: 0.3
    Contact: Wei Wang(oneway.wang\@utoronto.ca)

    Usage:   $0 vcf_file output_folder logfile
    Example: $0 ../ouput.vcf . log.txt
             $0 output.vcf fasta_folder log.txt

USAGE

if ($#ARGV < 1) {
    die $usage;
}

open (VCF, "$ARGV[0]") or die $!;
system("mkdir $ARGV[1]");
open (LOG, ">$ARGV[2]") or die $!;
my @indels = ();
my $now_pos = 0;
my $lastID = "";
my ($start, $stopp) = (0, 0);
my $position01 = 0;
VCF: while (<VCF>) {
    if (/^\#/) {
        if (/^\#\#UnifiedGenotyper.+input_file\=\[(.+?)\]/){
            @sample_list = split(/, /, $1);
            for (0..$#sample_list) {
                $sample_list[$_] =~ s/_stamp.+//;
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
            my $out_file = Bio::SeqIO->new( -file => ">$ARGV[1]/$out_file_name.fasta", -format => "fasta");
            for (0..$#sample_list) {
                my $real_length = length($out_twelve[2*$_]);
                my $show_length = $stopp - $start + 1;
                if ($real_length != $show_length) {
                    die "Length unequal! $real_length, $show_length, $out_file_name, $.\n$out_twelve[2*$_]\n";
                }
                my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
                $out_file->write_seq($seq_obj);
                $real_length = length($out_twelve[2*$_+1]);
                if ($real_length != $show_length) {
                    die "Length unequal!!! $real_length, $show_length, $out_file_name\n";
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
        if (length($snp[$_]) > 1 || length($line_ele[3] > 1)) {
            my $poss = $line_ele[1] - $start + 1;
            push @indels, $poss;
            last;
        }
    }
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
    if ($line_ele[5] < 60) {
        add_oneN(\@out_twelve);
        next;
    }
    if ($snp[0] eq '.') {
        add_refB(\@out_twelve, $line_ele[3]);
        next;
    }
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
        if ($dp < 20 || $gq < 60){
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
        my $out_file = Bio::SeqIO->new( -file => ">$ARGV[1]/$out_file_name.fasta", -format => "fasta");
        for (0..$#sample_list) {
            my $real_length = length($out_twelve[2*$_]);
            my $show_length = $stopp - $start + 1;
            if ($real_length != $show_length) {
                die "Length unequal! $out_file_name\n";
            }
            my $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_1_length_$real_length", -seq => $out_twelve[2*$_] );
            $out_file->write_seq($seq_obj);
            $real_length = length($out_twelve[2*$_+1]);
            if ($real_length != $show_length) {
                die "Length unequal! $real_length, $show_length, $out_file_name\n";
            }
            $seq_obj = Bio::Seq->new( -display_id => "$sample_list[$_]_2_length_$real_length", -seq => $out_twelve[2*$_+1] );
            $out_file->write_seq($seq_obj);
        }

sub add_refB {
    my $ref = shift;
    my $base = shift;
    for (0..$#$ref) {
        ${$ref}[$_] .= $base;
    }
}

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
