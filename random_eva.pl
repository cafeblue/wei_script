#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use PerlIO::gzip;

my $usage = << "USAGE";

    Usage: $0 fastq bam_file ref.fa ref.gtf
    Example: $0 Sample1_R1.fastq.gz ./tophat_Sample1/accepted_hits.bam HSA_build27.2.fa HSA_for_cufflinks.gtf

USAGE

if (@ARGV < 4) {
    die $usage;
}

system("samtools index $ARGV[1]");
my $seq = $ARGV[0];
$seq =~ s/\..+//;
$seq =~ s/ //g;
$seq =~ s/_R1//g;
$seq =~ s/_read1//g;


my $count = 0;
my $now_id = "";
my $line_check = 0;
my $gene_length = 0;
my @position_start = ();
my @position_stop = ();
my %id_parsed;
my @bin;

open (GTF,"$ARGV[3]") or die $!;
while (<GTF>) {
    my ($chr, $type, $start, $stop, $desc) = (split(/\t/, $_))[0,2,3,4,8];
    if (! $type =~ /exon/i) {
        next;
    }
    my $trans_id = "";
    if ($desc =~ /transcript_id "(.+?)";/) {
        $trans_id = $1;
    }
    else {
        die "gtf file error!\n";
    }

    if ($trans_id eq $now_id) {
        $gene_length += ($stop - $start) +1;
        $line_check = 0;
        push @position_start, $start;
        push @position_stop,  $stop;
        $id_parsed{$trans_id} = 1;
    }
    elsif ($line_check < 100) {
        $line_check++;
        $id_parsed{$trans_id} = 1;
        next;
    }
    else {
        if ($gene_length >= 20) {
            print $gene_length,"\t",$#position_start,"\t",$#position_stop,"\t",$trans_id,"\n";
            my $pos_count = 0;
            my %positions;
            my $now_region = "$chr:$position_start[0]-$position_stop[-1]";
            my %pos_cov = ();
            my @gene_pos = `samtools mpileup -d 100000 -r $now_region -f $ARGV[2] $ARGV[1] 2>/dev/null`;
            foreach (@gene_pos) {
                my ($tmp1,$tmp2,$tmp3,$tmp4) = split(/\t/, $_);
                $pos_cov{$tmp2} = $tmp4;
            }
            while ( my $exon_start = pop(@position_start)) {
                my $exon_stop = pop(@position_stop);
                for my $pos ($exon_start..$exon_stop) {
                    $pos_count++;
                    my $bin = int($pos_count*20/$gene_length);
                    if (exists $pos_cov{$pos}) {
                        push @{$positions{$bin}}, $pos_cov{$pos};
                    }
                    else {
                        push @{$positions{$bin}}, 0;
                    }
                }
            }
            for my $bin (0..19) {
                 my $cov_total = 0;
                 my $pos_count = 0;
                 print $#{$positions{$bin}},"\t";
                 foreach (@{$positions{$bin}}) {
                     $cov_total += $_;
                     $pos_count++;
                 }
                 $bin[$bin] += int($cov_total/$pos_count);
            }
            print "\n";
        }

        if (not exists $id_parsed{$trans_id}) {
            $line_check = 0; 
            $now_id = $trans_id;
            $count++;
            @position_start = ($start);
            @position_stop = ($stop);
            $gene_length = $stop - $start + 1;
            $id_parsed{$trans_id} = 1;
        }
        else {
            $line_check = 1000; 
            $gene_length = 0;
            @position_start = ();
            @position_stop = ();
            $gene_length = 0;
            next;
        }
    }

    if ($count >= 1001) {
        last;
    }
}
close(GTF);
open (BIN,">bin_$seq.txt") or die $!;
for (0..19) {
    my $bin_name = ($_ + 1) * 0.05;
    print BIN $bin_name,"\t",$bin[$_],"\n";
}
close(BIN);

system("Rscript ~/workdir/my_script/homogenicity.R bin_$seq.txt $seq homogenicity_$seq.pdf");
