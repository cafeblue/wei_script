#! /bin/env perl

use strict;
use File::Temp qw/ tempfile tempdir /;
use Getopt::Long;
use Bio::SeqIO;
use Bio::SearchIO;
use threads;

$|++;
my %opts;
GetOptions(\%opts, "t:s", "i:s", "o:s", "d:s");
my $ver= "0.2";
## version 0.2 ##
#  fix the bug of could not be used my other people.
#  add a creteria to filter the blast result (30% sequence similarity over at least 150 sites)
#  use getorf to predict the CDS for the sequences with no hit to nr databases.
#  output the AA sequences
#####
my $usage=<<"USAGE";

      Program : $0
      Version : $ver
      Contace : Wei Wang (oneway.wang\@utoronto.ca)

      Usage : $0 -i file_name -o string [-d database] [-t num] 
              -i file_name       Input file name of the transcriptome
              -o string          prefix of the output result files
              -t number          number of the threads [8] 
              -d database        to faster the pipeline, please select a special database to narrow 
                                 down the blastx search. options are below:
                                 viridiplantae (plant, default)
                                 metazoa (animal)
                                 archaea
                                 bacteria
                                 virus (virus and viroid)
                                 other_eu (eu other than green plants and animals)
                                 environment
                                 nr



USAGE

die $usage unless $opts{i} and $opts{o};

my $thread_number = 8;
if ($opts{t}) {
    $thread_number = $opts{t};
}

my $blast_db = "viridiplantae";
if ($opts{d}) {
    $blast_db = $opts{d};
}

my @workfasta = ();
#my $tempdir = File::Temp->newdir('t2frmXXXXXXXX', DIR => '.');
my $tempdir = tempdir('t2frmXXXXXXXX', DIR => '.', UNLINK => 0);
for (1..$thread_number) {
    my $temp = File::Temp->new( TEMPLATE => 'thrdXXXXXX', DIR => $tempdir, SUFFIX => '.fa', UNLINK => 0);
    push @workfasta, $temp;
}

my $seq_numbers = 0;
my $fasta = Bio::SeqIO->new( -file => "$opts{i}", -format => "fasta");
while (my $seq = $fasta->next_seq) {
    $seq_numbers++;
    my $nowfile = $seq_numbers % $thread_number;
    my $outfile = Bio::SeqIO->new( -foramt => 'fasta', -file => ">>$workfasta[$nowfile]" );
    $outfile->write_seq($seq);
}

my $err = File::Temp->new( TEMPLATE => 'XXXXX', DIR => '/dev/shm', UNLINK => 0);
my $output_nocds = File::Temp->new (TEMPLATE => "nogwXXXXXX", DIR => '/dev/shm', UFFIX => '.fa', UNLINK => 0);

my @thread;
for (0..$#workfasta) {
    $thread[$_] = threads->create("blastx_genewise_infram", "$workfasta[$_]");
}
for (0..$#workfasta) {
    $thread[$_]->join();
}

my $output_gff = $opts{o} . "_genewise.gff";
my $output_fa  = $opts{o} . "_genewise_inframe.fa";
my $output_nocds_orf = $opts{o} . "_getorf_inframe.fa";
system("touch $output_gff");
system("touch $output_fa");
foreach (@workfasta) {
    my $now_fa = $_;
    $now_fa =~ s/\.fa$/_out.fa/;
    my $now_gf = $_;
    $now_gf =~ s/\.fa$/.gff/;
    system ("cat $now_fa >> $output_fa");
    system ("cat $now_gf >> $output_gff");
    system ("rm $now_gf");
    $now_gf = $_;
    $now_gf =~ s/\.fa$/_nocds.fa/;
    system ("cat $now_gf >> $output_nocds");
    system ("rm $now_gf");
    $now_gf = $_;
    $now_gf =~ s/.+\///;
    system ("rm /dev/shm/$now_gf");
    $now_gf =~ s/\.fa/_in.fa/;
    system ("rm /dev/shm/$now_gf");
}

system ("getorf -sequence $output_nocds -outseq $err -find 0");
open (GETORF, "$err") or die $!;
my %getorf;
while(<GETORF>) {
    if (/^>(\S+_Length_(\d+))_\d+ \[(\d+) \- (\d+)\]/) {
        my $seq_out_id = $1;
        my $sta = 0;
        my $end = 0;
        my $str = '+';
        if ($3 > $4) {
            $sta = $2 - $3 + 1;
            $end = $2 - $4 + 1;
            $str = '-';
        }
        else {
            $sta = $3;
            $end = $4;
        }
        $seq_out_id =~ s/\/.+_Length/_Length/;
        if (exists $getorf{$seq_out_id}) {
            if ($getorf{$seq_out_id}{'len'} < ($end - $sta)){
                $getorf{$seq_out_id}{'len'} = ($end - $sta);
                $getorf{$seq_out_id}{'sta'} = $sta;
                $getorf{$seq_out_id}{'end'} = $end;
                $getorf{$seq_out_id}{'str'} = $str;
            }
        }
        else {
            $getorf{$seq_out_id}{'len'} = $end - $sta;
            $getorf{$seq_out_id}{'sta'} = $sta;
            $getorf{$seq_out_id}{'end'} = $end;
            $getorf{$seq_out_id}{'str'} = $str;
        }
    }
}
close(GETORF);
my $nocds_seq = Bio::SeqIO->new(-file => "$output_nocds", -format => 'fasta');
my $nocds_oufile = Bio::SeqIO->new(-file => ">$output_nocds_orf", -format=> "fasta");
while (my $seqnocds = $nocds_seq->next_seq()) {
    my $dispid = $seqnocds->display_id;
    $dispid =~ s/\/.+_Length/_Length/;
    if (exists $getorf{$dispid}) {
        my $seq_out_id_tmp = $dispid;
        $seq_out_id_tmp .= "_getorf__CDS__" . $getorf{$dispid}{'sta'} . "__" . $getorf{$dispid}{'end'};
        my $seq_out = Bio::Seq->new(-id  => $seq_out_id_tmp, -seq => $seqnocds->seq());
        if ($getorf{$dispid}{'str'} eq '-') {
            $seq_out = $seq_out->revcom;
        }
        $nocds_oufile->write_seq($seq_out);
    }
    else {
        die "$dispid does not exist in get orf output?!!\n";
    }
}

system ("rm $err $output_nocds");

sub blastx_genewise_infram {
    my $fasta = pop;
    my %fasta;
    my $qsub = $fasta;
    $qsub =~ s/fa$/qsub/;
    my $outb = $fasta;
    $outb =~ s/\.fa$/_1e-3.blastx/;
    my $outgff = $fasta;
    $outgff =~ s/\.fa$/.gff/;
    my $outfa = $fasta;
    $outfa =~ s/\.fa$/_out.fa/;
    my $out_nocds = $fasta;
    $out_nocds =~ s/.fa$/_nocds.fa/;
    my $gw_pep = $fasta;
    $gw_pep =~ s/.+\///;
    my $gw_nuc = $gw_pep;
    $gw_nuc =~ s/\.fa$/_in.fa/;

    system("blastx -query $fasta -out $outb -db /cap1/wei.wang/databases/ncbi/$blast_db -evalue 1e-3 -num_alignments 10 -num_descriptions 10");

    my $seq = Bio::SeqIO->new( -file => "$fasta", -format => 'fasta');
    my $out_seq_file = Bio::SeqIO->new( -file => ">$outfa", -format => "fasta");
    open (GFF, ">$outgff") or die $!;
    while (my $seqobj = $seq->next_seq) {
        my $print = $seqobj->display_id();
        $fasta{$print} = $seqobj;
    }

    my $blast = Bio::SearchIO->new( -file => "$outb", -format => 'blast');
    while (my $result = $blast->next_result) {
        if ($result->num_hits  == 0) {
            my $outfile_nocds = Bio::SeqIO->new( -foramt => 'fasta', -file => ">>$out_nocds" );
            $outfile_nocds->write_seq($fasta{$result->query_name})
        }
        else {
            my $hitobj = $result->next_hit;
            my $hsp = $hitobj->next_hsp;
            if ($hsp->frac_conserved('query') < 0.3 || $hsp->length('query') < 150 ) {
                my $outfile_nocds = Bio::SeqIO->new( -foramt => 'fasta', -file => ">>$out_nocds" );
                $outfile_nocds->write_seq($fasta{$result->query_name});
                next;
            }
            my $seqid = $hitobj->name();
            system("blastdbcmd -db /cap1/wei.wang/databases/ncbi/$blast_db -entry \'$seqid\' > /dev/shm/$gw_pep ");
            $seq = Bio::SeqIO->new( -file => ">/dev/shm/$gw_nuc", -format => "fasta");
            $seq->write_seq($fasta{$result->query_name});
            my $seq_out = $fasta{$result->query_name};
            my $gw_cmd = "genewise /dev/shm/$gw_pep /dev/shm/$gw_nuc";
            if ($hsp->strand('query') == -1) {
                $gw_cmd .= " -trev -gff 2>$err";
            }
            elsif ($hsp->strand('query') == 1) {
                $gw_cmd .= " -gff  2>$err";
            }
            my $gff = `$gw_cmd`;
            print GFF $gff;
            my @gff = split(/\n/, $gff);
            my $cds = "";
            my $cds_length = 0;
            my @cds_edge = ();
            foreach (@gff) {
                my ($type, $start,$stopp,$strand,$phase) = (split(/\t/, $_))[2,3,4,6,7];
                if ($type eq 'cds') {
                    if ($#cds_edge == -1) {
                        push @cds_edge, $start;
                        push @cds_edge, $stopp;
                    }
                    else {
                        $cds_edge[1] = $stopp;
                    }
                    if ($strand eq '-') {
                        $cds = $seq_out->subseq($stopp, $start) . $cds;
                        $cds_length += ($start - $stopp + 1);
                    }
                    elsif ($strand eq '+') {
                        $cds .= $seq_out->subseq($start, $stopp);
                        $cds_length += ($stopp - $start + 1);
                    }
                    else {
                        die "strand error? $strand \n";
                    }
                }
            }
            my $seq_out_cdsstt = 0;
            my $seq_out_cdsstp = 0;
            if ($cds_edge[0] > $cds_edge[1]) {
                $seq_out_cdsstt = $result->query_length - $cds_edge[0] + 1;
                $seq_out_cdsstp = $seq_out_cdsstt + $cds_length - 1;
                my $p5 = "";
                if ($cds_edge[1] != 1) {
                    $p5 = $seq_out->subseq($cds_edge[0]+1,$result->query_length);
                }
                my $p3 = "";
                if ($cds_edge[0] != $result->query_length) {
                    $p3 = $seq_out->subseq(1, $cds_edge[1]-1);
                }
                my $seq_out_seq = $p3 . $cds . $p5;
                my $seq_out_id = $result->query_name;
                $seq_out_id =~ s/\/.+_Length/_Length/;
                $seq_out_id .= "_genewise_newlength_" . length($seq_out_seq);
                $seq_out_id .= "__CDS__$seq_out_cdsstt" . "__$seq_out_cdsstp";
                $seq_out = Bio::Seq->new(-id  => $seq_out_id, -seq => $seq_out_seq);
                $seq_out = $seq_out->revcom;
                $out_seq_file->write_seq($seq_out);
            }
            elsif ($cds_edge[0] < $cds_edge[1]) {
                $seq_out_cdsstt = $cds_edge[0];
                $seq_out_cdsstp = $seq_out_cdsstt + $cds_length - 1;
                my $p5 = "";
                if ($cds_edge[0] != 1) {
                    $p5 = $seq_out->subseq(1, $cds_edge[0]-1);
                }
                my $p3 = "";
                if ($cds_edge[1] != $result->query_length) {
                    $p3 = $seq_out->subseq($cds_edge[1]+1,$result->query_length);
                }
                my $seq_out_seq = $p5 . $cds . $p3;
                my $seq_out_id = $result->query_name;
                $seq_out_id =~ s/\/.+_Length/_Length/;
                $seq_out_id .= "_genewise_newlength_" . length($seq_out_seq);
                $seq_out_id .= "__CDS__$seq_out_cdsstt" . "__$seq_out_cdsstp";
                $seq_out = Bio::Seq->new(-id  => $seq_out_id, -seq => $seq_out_seq);
                $out_seq_file->write_seq($seq_out);
            }
            else {
                die "no CDS region? $cds_edge[0], $cds_edge[1], ",$result->query_name, "\n"
            }
        }
    }
}
