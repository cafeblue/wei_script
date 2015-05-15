#! /share/data/software/ActivePerl-5.12/bin/perl

use strict;
use PerlIO::gzip;
use File::Temp qw( tmpfile );

my $usage = << "USAGE";

    Usage: $0 fastq_file bam_file ref.gtf
    Example: $0 Sample1_R1.fastq.gz ./tophat_Sample1/accepted_hits.bam HSA_for_cufflinks.gtf

USAGE

if (@ARGV < 3) {
    die $usage;
}

my $tmpdir = File::Temp->newdir();
my $summary;
system ("samtools view -o $tmpdir/all.sam $ARGV[1]");
my $command = 'awk \'{print $1}\' '." $tmpdir/all.sam |sort|uniq>$ARGV[1].mappedid";
system ($command);
my $head = `samtools view -H $ARGV[1]`;
 
if ($ARGV[0] =~ /\.gz$/) {
    open (SEQIN, "<:gzip", "$ARGV[0]") or die $!;
}
else {
    open (SEQIN, "$ARGV[0]") or die $!;
}

my $seq = $ARGV[0];
$seq =~ s/\..+//;
$seq =~ s/ //g;
$seq =~ s/_R1//g;
$seq =~ s/_read1//g;
$summary = $seq;

my %id_list;
my $count = 0;
#my $total_reads = `zcat $ARGV[0] |wc -l`;
#chomp($total_reads);
#$total_reads /= 4;
#if ($total_reads >= 16000000) {
    while (<SEQIN>) {
        if ($. % 4 == 1) {
            chomp;
            s/^@//;
            s/ .+//;
#            if (rand(40) <=10) {
                $id_list{$_} = int(rand(10));
#                $count++;
#            }
        }
#        elsif ($count >= 4000000) {
#            last;
#        }
    }
#}
my $total_reads = $./4;
$summary .= "\t$total_reads";

close(SEQIN);

open (SAM, "$tmpdir/all.sam") or die $!;
open (SAM0, ">$tmpdir/sam0.sam") or die $!;
print SAM0 $head;
open (SAM1, ">$tmpdir/sam1.sam") or die $!;
print SAM1 $head;
open (SAM2, ">$tmpdir/sam2.sam") or die $!;
print SAM2 $head;
open (SAM3, ">$tmpdir/sam3.sam") or die $!;
print SAM3 $head;
open (SAM4, ">$tmpdir/sam4.sam") or die $!;
print SAM4 $head;
open (SAM5, ">$tmpdir/sam5.sam") or die $!;
print SAM5 $head;
open (SAM6, ">$tmpdir/sam6.sam") or die $!;
print SAM6 $head;
open (SAM7, ">$tmpdir/sam7.sam") or die $!;
print SAM7 $head;
open (SAM8, ">$tmpdir/sam8.sam") or die $!;
print SAM8 $head;
open (SAM9, ">$tmpdir/sam9.sam") or die $!;
print SAM9 $head;
while (<SAM>) {
    my $id = (split(/\t/, $_))[0];
    if (not exists $id_list{$id}) {
        next;
    }
    elsif ($id_list{$id} == 0) {
        print SAM0 $_;
    }
    elsif ($id_list{$id} == 1) {
        print SAM1 $_;
    }
    elsif ($id_list{$id} == 2) {
        print SAM2 $_;
    }
    elsif ($id_list{$id} == 3) {
        print SAM3 $_;
    }
    elsif ($id_list{$id} == 4) {
        print SAM4 $_;
    }
    elsif ($id_list{$id} == 5) {
        print SAM5 $_;
    }
    elsif ($id_list{$id} == 6) {
        print SAM6 $_;
    }
    elsif ($id_list{$id} == 7) {
        print SAM7 $_;
    }
    elsif ($id_list{$id} == 8) {
        print SAM8 $_;
    }
    elsif ($id_list{$id} == 9) {
        print SAM9 $_;
    }
}
$summary .= "\t$.";

close(SAM);
close(SAM0);
close(SAM1);
close(SAM2);
close(SAM3);
close(SAM4);
close(SAM5);
close(SAM6);
close(SAM7);
close(SAM8);
close(SAM9);

system("cufflinks --no-update-check -o $tmpdir/sam0_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam0.sam");
system("cufflinks --no-update-check -o $tmpdir/sam1_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam1.sam");
system("cufflinks --no-update-check -o $tmpdir/sam2_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam2.sam");
system("cufflinks --no-update-check -o $tmpdir/sam3_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam3.sam");
system("cufflinks --no-update-check -o $tmpdir/sam4_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam4.sam");
system("cufflinks --no-update-check -o $tmpdir/sam5_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam5.sam");
system("cufflinks --no-update-check -o $tmpdir/sam6_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam6.sam");
system("cufflinks --no-update-check -o $tmpdir/sam7_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam7.sam");
system("cufflinks --no-update-check -o $tmpdir/sam8_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam8.sam");
system("cufflinks --no-update-check -o $tmpdir/sam9_cufflinks -p 4 -G $ARGV[2] $tmpdir/sam9.sam");

my %genes;
my @rpkm_files = `ls $tmpdir/sam?_cufflinks/isoforms.fpkm_tracking`;
open (OUP, ">degree_of_saturation_$seq.txt") or die $!;
my $level = 0;
foreach my $rpkm_file (@rpkm_files) {
    my $count = 0;
    chomp($rpkm_file);
    open (RPKM, "$rpkm_file") or die $!;
    my $line = <RPKM>;
    while ($line = <RPKM>) {
        my($iso, $yes) = (split(/\t/, $line))[0,8];
        if (not exists $genes{$iso}) {
            $genes{$iso} = $yes;
        }
        else {
            $genes{$iso} += $yes;
        }
    }
    $level += 10;
    foreach (keys %genes) {
        if ($genes{$_} >=1) {
            $count++;
        }
    }
    print OUP $level,"\%\t",$count,"\n";
    close(RPKM);
    if ($level == 100) {
        $summary .= "\t$count";
    }
}
close(OUP);

system ("Rscript ~/workdir/my_script/saturation.R degree_of_saturation_$seq.txt $seq Saturation_Eva_$seq.pdf");
system ("echo $summary >> summary.txt");
