#! /usr/bin/env perl

##########################################################################
#                                                                        #
#  ARGV[0] is refGene.txt file for this species.                         #
#  ARGV[1] is the txt file which snp annotation items excluded.          #
#  ARGV[2] is the output file.                                           #
#                                                                        #
#  Usage:                                                                #
#     vcf_nodbsnp_anno.pl refGene.txt hsa_snp_nodbsnp.txt out.txt        #
#                                                                        #
##########################################################################


use strict;

my %all_pos;
#open (GTF, "/home/wangw/workdir/genome/gtf/HSA_for_cufflinks.gtf") or die $!;
#open (GTF, "te") or die $!;

my $usage = <<"USAGE";

        Program : $0                                                                                                                                           
        Contact : Wang Wei                                                                                                                                     
        Usage : $0 refGene.txt nodbsnp_list.txt output.txt 

USAGE
 
if (@ARGV < 3) {
    die $usage;
}

my @refgene = `sort -k 3,3 -k 5n,5 $ARGV[0]`;

my $i = 0;
my @all_acc_name;

foreach my $gtf_line (@refgene) {
#for (0..$#refgene) {
#    my $gtf_line = $refgene[$_];
    my ( $acc, $chr, $start, $stop, $name) = (split(/\t/, $gtf_line))[1,2,4,5,12];
#    $chr = pack('Z5', $chr);
#    my $acc_name = pack('Z30', "$acc\t$name");
#    push @all_acc_name, $acc_name;
    $i++;
    $all_pos{$i}{$chr}{'start'} = $start;
    $all_pos{$i}{$chr}{'stop'} = $stop;
    $all_pos{$i}{$chr}{'name'} = "\t$acc\t$name";
}

$i=0;
#open (SNP, "/home/wangw/newworkdir/BFC2011142/combine_uniq_gt4_nodbsnp.txt") or die $!;
open (SNP, "$ARGV[1]") or die $!;
open (OUF, ">$ARGV[2]") or die $!;
while (my $snp = <SNP>) {
    chomp($snp);
    my ($chr, $pos, $yes) = (split(/\t/, $snp))[0,1,8];
    if ($yes eq "dbsnp") {
        print OUF $snp,"\n";
        next;
    }
    while (1) {
        if (not exists $all_pos{$i}{$chr}) {
            print OUF $snp,"\n";
            $i++;
            last;
        }
        elsif ($all_pos{$i}{$chr}{'start'} > $pos) {
            print OUF $snp,"\n";
            last;
        }
        elsif ($all_pos{$i}{$chr}{'stop'} < $pos) {
            $i++;
            next;
        }
        else {
            print OUF $snp,$all_pos{$i}{$chr}{'name'},"\n";
            last;
        }
    }
}
