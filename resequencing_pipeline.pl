#! /share/data/software/ActivePerl-5.12/bin/perl

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
# q1=./sample1.fq.gz
#
# [lib_pe]
# q1=./sample3_read1.fq.gz
# q2=./sample3_read2.fq.gz
# INSERTSIZE=380
#
# [map]
# REF=/home/wangw/workdir/genome/bowtie/hg19.fa
# 
# [refGene]
# RGE=/share/data/database/refGene.txt
#
# [dbSNP]
# SNP=/share/data/staff/sunchy/data/dbsnp/snp131.txt
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
my $seq_file;
my $seq_file2;
my $ref;
my $insertsize = 0;
my $snp = "";
my $rge = "";

while (<CONF>) {
    chomp;
    if (/^q1\=(.+)/) {
        $seq_file = $1;
    }
    elsif (/^q2\=(.+)/) {
        $seq_file2 = $1;
    }
    elsif (/^REF\=(.+)/) {
        $ref = $1;
    }
    elsif (/^INSERTSIZE=(.+)/) {
        $insertsize = $1;
    }
    elsif (/^RGE=(.+)/) {
        $rge = $1;
    }
    elsif (/^SNP=(.+)/) {
        $snp = $1;
    }
}

my $sai1 = $seq_file;
$sai1 =~ s/.+\///;
$sai1 =~ s/\..+//;
my $sample_name = $sai1;
$sample_name =~ s/_R1//;
$sample_name =~ s/_read1//;
my $sort = $sample_name ."_sort";
my $bam_sort_rmdup = $sort . "_rmdup";

system("bwa aln -n 5 -t 16 -l 50 -f $sai1.sai $ref $seq_file");
if ($seq_file2) {
    my $sai2 = $seq_file2;
    $sai2 =~ s/.+\///;
    $sai2 =~ s/\..+//;
    system("bwa aln -n 5 -t 16 -l 50 -f $sai2.sai $ref $seq_file2");
    system("bwa sampe -f $sample_name.sam -a $insertsize $ref $sai1.sai $sai2.sai $seq_file $seq_file2");
}
else {
    system("bwa samse -f $sample_name.sam $ref $sai1.sai $seq_file");
}
system("samtools view -bS -o $sample_name.bam $sample_name.sam");
system("samtools sort $sample_name.bam $sort");
system("samtools rmdup $sort.bam $bam_sort_rmdup.bam");
#system("samtools view -o $sam_sort_rmdup.sam $bam_sort_rmdup.bam");
system("samtools depth $bam_sort_rmdup.bam > $sample_name.coverage");
system("Rscript ~/workdir/my_script/coverage_distr.R $sample_name.coverage $sample_name\_coverage_distribution.pdf");
system("samtools mpileup -ugf ref $bam_sort_rmdup.bam | bcftools view -bvcg - > $sample_name.bcf");
system("bcftools view $sample_name.bcf | vcfutils.pl varFilter > $sample_name.vcf");
if ($snp ne "") {
    system("vcf2snp.pl $sample_name.vcf $sample_name\_snp.txt $sample_name\_indel.txt $sample_name\_stat.txt");
    system("ex_dbSNP_4.4_anno.pl $sample_name\_snp.txt $snp $sample_name\_dbsnp_annotated.txt");
    system("sed -i \'1,12d\' $sample_name\_dbsnp_annotated.txt");
}

if ($rge ne "" && $snp ne "") {
    system("vcf_nodbsnp_anno.pl $rge $sample_name\_dbsnp_annotated.txt $sample_name\_snp_all_annotated.txt");
}
elsif ($rge ne "") {
    system("vcf2snp.pl $sample_name.vcf $sample_name\_snp.txt $sample_name\_indel.txt $sample_name\_stat.txt");
    system("vcf_nodbsnp_anno.pl $rge $sample_name\_snp.txt $sample_name\_snp_all_annotated.txt");
}
elsif ($snp eq "") {
    system("vcf2snp_xlsx.pl $sample_name.vcf $sample_name.xlsx $sample_name.summary.xlsx");
}
