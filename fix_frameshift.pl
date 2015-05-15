#! /bin/env perl

use strict;
use Bio::SeqIO;

if (@ARGV < 3) {
    die "\n\tUsage: perl $0 old_fasta.fa new_fasta.fa id_fixed.txt\n\tExample: perl $0 rumex_inframe.fa remex_inframe_fixed.fa id.txt\n\n";
}

my $infile = Bio::SeqIO->new( -file => "$ARGV[0]" );
my $outfil = Bio::SeqIO->new( -file => ">$ARGV[1]" );
open (FIX, ">$ARGV[2]") or die $!;

my $nums = 0;
while (my $seqobj = $infile->next_seq()) {
    my $id = $seqobj->display_id();
    my ($ida , $idb, $start, $end) = split(/__/, $id);
    my $cds_seq = $seqobj->subseq($start, $end);
    my $new_seqobj = Bio::Seq->new( -id => "cds", -seq => $cds_seq);
    my $new_trans = $new_seqobj->translate;
    my $tmpaaseq = $new_trans->seq();
    if ($tmpaaseq =~ /\*/) {
        my $number = () = $tmpaaseq =~ /\*/gi;
        if ($start < 3 && $end+1 < $seqobj->length) {
            $start++;
            $end++;
            $cds_seq = $seqobj->subseq($start, $end);
            my $new_seqobj1 = Bio::Seq->new( -id => join("__", ($ida, $idb, $start, $end)), -seq => $cds_seq);
            $new_trans = $new_seqobj1->translate;
            my $tmpaaseq1 = $new_trans->seq();
            my $number1 = () = $tmpaaseq1 =~ /\*/gi;
            if ($tmpaaseq1 =~ /\*/) {
                $start++;
                $end++;
                $cds_seq = $seqobj->subseq($start, $end);
                my $new_seqobj2 = Bio::Seq->new( -id => join("__", ($ida, $idb, $start, $end)), -seq => $cds_seq);
                $new_trans = $new_seqobj2->translate;
                my $tmpaaseq2 = $new_trans->seq();
                my $number2 = () = $tmpaaseq2 =~ /\*/gi;
                if ($tmpaaseq2 =~ /\*/) {
                    if ($number > 1 && $number1 > 1 && $number2 > 1) {
                        print STDERR $id," can not be fixed!\n";
                    }
                    elsif ($number == 1) {
                        $outfil->write_seq($seqobj);
                    }
                    elsif ($number1 == 1) {
                        $outfil->write_seq($new_seqobj1);
                        print FIX "$id\t+1\*\n";
                    }
                    elsif ($number2 == 1) {
                        $outfil->write_seq($new_seqobj2);
                        print FIX "$id\t+2\*\n";
                    }
                    else { 
                        die "$id: $number $number1 $number2 impossible happend!\n";
                    }
                    
                }
                else {
                    $outfil->write_seq($new_seqobj2);
                    print FIX "$id\t+2\n";
                }
            }
            else {
                $outfil->write_seq($new_seqobj1);
                print FIX "$id\t+1\n";
            }
        }
        elsif ($start < 3 && $end+1 >= length($cds_seq)) {
            $outfil->write_seq($seqobj);
            if ($number > 1) {
                print STDERR $id," can not be full fixed!\n";
                print STDERR $tmpaaseq,"\n";
                print STDERR $end,"\t",$seqobj->length,"\n";
            }
        }
        else {
            $start--;
            $end--;
            $cds_seq = $seqobj->subseq($start, $end);
            my $new_seqobj1 = Bio::Seq->new( -id => join("__", ($ida, $idb, $start, $end)), -seq => $cds_seq);
            $new_trans = $new_seqobj1->translate;
            my $tmpaaseq1 = $new_trans->seq();
            my $number1 = () = $tmpaaseq1 =~ /\*/gi;
            if ($tmpaaseq1 =~ /\*/) {
                $start--;
                $end--;
                $cds_seq = $seqobj->subseq($start, $end);
                my $new_seqobj2 = Bio::Seq->new( -id => join("__", ($ida, $idb, $start, $end)), -seq => $cds_seq);
                $new_trans = $new_seqobj2->translate;
                my $tmpaaseq2 = $new_trans->seq();
                my $number2 = () = $tmpaaseq2 =~ /\*/gi;
                if ($tmpaaseq2 =~ /\*/) {
                    if ($number > 1 && $number1 > 1 && $number2 > 1) {
                        print STDERR $id," can not be fixed!\n";
                    }
                    elsif ($number == 1) {
                        $outfil->write_seq($seqobj);
                    }
                    elsif ($number1 == 1) {
                        $outfil->write_seq($new_seqobj1);
                        print FIX "$id\t-1\*\n";
                    }
                    elsif ($number2 == 1) {
                        $outfil->write_seq($new_seqobj2);
                        print FIX "$id\t-2\*\n";
                    }
                    else { 
                        die "$id: $number $number1 $number2 impossible happend!\n";
                    }
                }
                else {
                    $outfil->write_seq($new_seqobj2);
                    print FIX "$id\t-2\n";
                }
            }
            else {
                $outfil->write_seq($new_seqobj1);
                print FIX "$id\t-1\n";
            }
        }
    }
    else {
        $outfil->write_seq($seqobj);
    }
}
