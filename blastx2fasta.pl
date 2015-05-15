#! /bin/env  perl

use strict;
use Bio::SearchIO;
use Bio::SeqIO;

$|++;
my %fasta;
my $seq = Bio::SeqIO->new( -file => "$ARGV[0]", -format => 'fasta');
my $out_seq_file = Bio::SeqIO->new( -file => ">$ARGV[2]", -format => "fasta");
open (GFF, ">genewise.gff") or die $!;
while (my $seqobj = $seq->next_seq) {
    my $print = $seqobj->display_id();
    $fasta{$print} = $seqobj;
}

my $blast = Bio::SearchIO->new( -file => "$ARGV[1]", -format => 'blast');
while (my $result = $blast->next_result) {
    if ($result->num_hits  == 0) {
        print STDERR $result->query_name,"\n";
    }
    else {
        my $hitobj = $result->next_hit;
        my $hsp = $hitobj->next_hsp;
        #print $result->query_name,"\t",$hitobj->name(),"\t", $hsp->start('query'), "\t",$hsp->end('query'),"\t",$hsp->num_identical(), "\t", $hsp->num_conserved(),"\n";
        #print $hsp->strand('query'),"\n";
        my $seqid = $hitobj->name();
        system("blastdbcmd -db viridiplantae -entry \'$seqid\' > /dev/shm/pep.fa ");
        $seq = Bio::SeqIO->new( -file => ">/dev/shm/query.fa", -format => "fasta");
        $seq->write_seq($fasta{$result->query_name});
        my $seq_out = $fasta{$result->query_name};
        my $gw_cmd = "/data/wei.wang/wise-2.4.1/src/bin/genewise /dev/shm/pep.fa /dev/shm/query.fa";
        if ($hsp->strand('query') == -1) {
            $gw_cmd .= " -trev -gff 2>/dev/null";
        }
        elsif ($hsp->strand('query') == 1) {
            $gw_cmd .= " -gff  2>/dev/null";
        }
        #system($gw_cmd);
        my $gff = `$gw_cmd`;
        print GFF $gff;
        my @gff = split(/\n/, $gff);
        my $cds = "";
        my $cds_length = 0;
        my @cds_edge = ();
        foreach (@gff) {
            my ($type, $start,$stopp,$strand) = (split(/\t/, $_))[2,3,4,6];
            if ($type eq 'cds') {
                if ($#cds_edge == -1) {
                    push @cds_edge, $start;
                    push @cds_edge, $stopp;
                }
                else {
                    $cds_edge[1] = $stopp;
                }
                if ($strand eq '-') {
                    $cds .= $seq_out->subseq($stopp, $start);
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
            #my $p5 = ""; 
            #if ($cds_edge[0] != $result->query_length) {
            #    $p5 = $seq_out->subseq($cds_edge[0]+1, $result->query_length);
            #}
            #my $p3 = "";
            #if ($cds_edge[1] != 1) {
            #    $p3 = $seq_out->subseq(1, $cds_edge[1]-1 );
            #}
            my $p5 = "";
            if ($cds_edge[1] != 1) {
                $p5 = $seq_out->subseq(1, $cds_edge[1]-1);
            }
            my $p3 = "";
            if ($cds_edge[0] != $result->query_length) {
                $p3 = $seq_out->subseq($cds_edge[0]+1,$result->query_length);
            }
            my $seq_out_seq = $p5 . $cds . $p3;
            #my $seq_out_id = $result->query_name . "__CDS__$seq_out_cdsstt" . "__$seq_out_cdsstp";
            my $seq_out_id = $result->query_name;
            $seq_out_id =~ s/\/.+_Length/_Length/;
            $seq_out_id .= "_newlength_" . length($seq_out_seq);
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
            #my $seq_out_id = $result->query_name . "__CDS__$seq_out_cdsstt" . "__$seq_out_cdsstp";
            my $seq_out_id = $result->query_name;
            $seq_out_id =~ s/\/.+_Length/_Length/;
            $seq_out_id .= "_newlength_" . length($seq_out_seq);
            $seq_out_id .= "__CDS__$seq_out_cdsstt" . "__$seq_out_cdsstp";
            $seq_out = Bio::Seq->new(-id  => $seq_out_id, -seq => $seq_out_seq);
            $out_seq_file->write_seq($seq_out);
        }
        else {
            die "no CDS region? $cds_edge[0], $cds_edge[1], ",$result->query_name, "\n"
        }
    }
}
