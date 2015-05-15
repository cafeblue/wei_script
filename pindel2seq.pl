#! /bin/env perl
#
#Extract sequences from the pindel output.

use strict;
use Bio::SeqIO;
use Getopt::Std;

my %opts;
my $usage = << "USAGE";

    Program: extract sequences from the pindel output.
    Contact: Wei Wang (oneway.wang\@utoronto.ca)
    Usage: 
        $0 -f reference.fa -i prefix_pindel_result_file -o output_prefix -T [D|I|V|S|U]
            -f referene fasta file.
            -i prefix of the pindel output file.
            -o prefix of output file. [seq_output].
            -T type of the SV: Deletion(D), inVersion(V), Insertion(I), Short insertion(S) and Unknown(U)
                other letters will be ignored.
            -s threadhold of support reads number.[10]
            -k length of sequences extract from the break point flank.[10]
            -e threadhold length of the shortest insersion you want to extract.[80]

    Example:
        $0 -f reference.fa -i pindel -T DIVUS

USAGE

getopt('ifoTske', \%opts);

if (!($opts{f} && $opts{T} && $opts{i})) {
    die $usage;
}

my $sup_reads_thh = $opts{s}?$opts{s}:10;
my $flank_seq_length = $opts{k}?$opts{k}:10;
my $out_prefix = $opts{o}?$opts{o}:"seq_output";
my $length_li = $opts{e}?$opts{e}:80;

my $infile;
my $outfile;

if ($opts{T} =~ /I/) {
    $outfile= Bio::SeqIO->new(-file => ">$out_prefix\_LI.fasta", -format => "Fasta");
    insertion_seq();
}

if ($opts{T} =~ /D/) {
    $infile = Bio::SeqIO->new(-file =>"$opts{f}", -format => "Fasta");
    $outfile= Bio::SeqIO->new(-file => ">$out_prefix\_D.fasta", -format => "Fasta");
    deletion_seq();
}

if ($opts{T} =~ /V/) {
    $infile = Bio::SeqIO->new(-file =>"$opts{f}", -format => "Fasta");
    $outfile= Bio::SeqIO->new(-file => ">$out_prefix\_INV.fasta", -format => "Fasta");
    inversion_seq();
}

if ($opts{T} =~ /U/) {
    $outfile= Bio::SeqIO->new(-file => ">$out_prefix\_BP.fasta", -format => "Fasta");
    otherBP_seq();
}

if ($opts{T} =~ /S/) {
    $outfile= Bio::SeqIO->new(-file => ">$out_prefix\_SI.fasta", -format => "Fasta");
    shortins_seq();
}

sub insertion_seq {
    my %pos_list;
    my $line = "";
    open(INSEF, "$opts{i}_LI") or die $!;
    while (<INSEF>) {
        if (/^\d/) {
            my $out5 = "";
            my $out3 = "";
            my ($chrID, $pos, $sup1, $sup2) = (split(/\s+/, $_))[3,4,6,9];
            if ($sup1 >= $sup_reads_thh|| $sup2 >= $sup_reads_thh) {
                $line = <INSEF>;
                $line =~ s/a|t|g|c|n//g;
                chomp($line);
                my $length_ref = length($line);
                for (1..$sup1) {
                    $line = <INSEF>;
                    my $subline = substr $line, $length_ref;
                    $subline =~ s/\s.+//g;
                    chomp($subline);
                    if (length($subline) > length($out5)) {
                        $out5 = $subline;
                    }
                }
                $line = <INSEF>;
                $line = <INSEF>;
                $line =~ s/A|T|G|C|N//g;
                chomp($line);
                $length_ref = length($line);
                for (1..$sup2) {
                    $line = <INSEF>;
                    my $subline = substr $line, 0, $length_ref;
                    $subline =~ s/^\s+//;
                    if (length($subline) > length($out3)) {
                        $out3 = $subline;
                    }
                }
                my $seq = $out5 . "N" x 200 . $out3;
                my $id = "$chrID\_$pos\_SR_$sup1\_$sup2";
                my $seqobj_out = Bio::PrimarySeq->new ( -seq => "$seq", -id  => "$id", -alphabet => 'dna'); 
                $outfile->write_seq($seqobj_out);
            }
        }
    }
}

sub deletion_seq {
    my %pos_list;
    open (DELEF, "$opts{i}_D") or die $!;
    open (DELE_NT, ">$out_prefix\_D.NT_seq") or die $!;
    while (<DELEF>) {
        if (/^\d/) {
            my ($length, $nt_length, $nt_seq, $chrID, $start, $stop, $support_reads) = 
            (split(/\s+/, $_))[2,4,5,7,12,13,16];
            if ($length < $length_li|| $support_reads < $sup_reads_thh) {
                next;
            }
            elsif ($nt_length != 0 ) {
                my $new_id = "$chrID\_$start\_$stop\_SR_$support_reads\_NT_$nt_length\_length_$length";
                $pos_list{$chrID}{$new_id}{'start'} = $start;
                $pos_list{$chrID}{$new_id}{'stop'} = $stop;
                print DELE_NT $_;
            }
            else {
                my $new_id = "$chrID\_$start\_$stop\_SR_$support_reads\_length_$length";
                $pos_list{$chrID}{$new_id}{'start'} = $start;
                $pos_list{$chrID}{$new_id}{'stop'} = $stop;
            }
        }
    }
    while (my $seqobj = $infile->next_seq()) {
        foreach (keys %{$pos_list{$seqobj->display_id()}}) {
            my $seq = $seqobj->subseq($pos_list{$seqobj->display_id()}{$_}{'start'}-$flank_seq_length,$pos_list{$seqobj->display_id()}{$_}{'stop'}+$flank_seq_length);
            my $seqobj_out = Bio::PrimarySeq->new ( -seq => "$seq", -id  => "$_", -alphabet => 'dna');
            $outfile->write_seq($seqobj_out);
        }
    }
}

sub inversion_seq {
    my %pos_list;
    open (INVF, "$opts{i}_INV") or die $!;
    while (<INVF>) {
        if (/^\d/) {
            my ($length, $nt_length, $nt_seq, $chrID, $start, $stop, $support_reads) = 
            (split(/\s+/, $_))[2,4,5,7,12,13,16];
            my $nt_5 = "";
            my $nt_3 = "";
            if ($length < $length_li|| $support_reads < $sup_reads_thh) {
                next;
            }
            elsif ($nt_length ne "0:0") {
                ($nt_5, $nt_3) = split(/:/, $nt_seq);
                $nt_5 =~ s/\"//g;
                $nt_3 =~ s/\"//g;
                my $new_id = "$chrID\_$start\_$stop\_SR_$support_reads\_NT_$nt_length\_length_$length";
                $pos_list{$chrID}{$new_id}{'start'} = $start;
                $pos_list{$chrID}{$new_id}{'stop'} = $stop;
                $pos_list{$chrID}{$new_id}{'nt5'} = $nt_5;
                $pos_list{$chrID}{$new_id}{'nt3'} = $nt_3;
            }
            else {
                my $new_id = "$chrID\_$start\_$stop\_SR_$support_reads\_length_$length";
                $pos_list{$chrID}{$new_id}{'start'} = $start;
                $pos_list{$chrID}{$new_id}{'stop'} = $stop;
                $pos_list{$chrID}{$new_id}{'nt5'} = $nt_5;
                $pos_list{$chrID}{$new_id}{'nt3'} = $nt_3;
            }
        }
    }
    while (my $seqobj = $infile->next_seq()) {
        foreach (keys %{$pos_list{$seqobj->display_id()}}) {
            my $seq = $seqobj->subseq($pos_list{$seqobj->display_id()}{$_}{'start'},$pos_list{$seqobj->display_id()}{$_}{'stop'});
            $seq = $seq . $pos_list{$seqobj->display_id()}{$_}{'nt3'};
            $seq = $pos_list{$seqobj->display_id()}{$_}{'nt5'} . $seq;
            my $seqobj_out = Bio::PrimarySeq->new ( -seq => "$seq", -id  => "$_", -alphabet => 'dna');
            $outfile->write_seq($seqobj_out);
        }
    }
}

sub otherBP_seq {
    my %pos_list;
    my $line = "";
    open (BP, "$opts{i}_BP") or die $!;
    while (<BP>) {
        if (/^ChrID/) {
            my ($chrID, $pos, $chain, $support_reads) = (split(/\s+/, $_))[1,2,3,4];
            my $out5 = "";
            my $out3 = "";
            if ($support_reads > $sup_reads_thh) {
                $line = <BP>;
                if ($chain eq "+") {
                    chomp($line);
                    $line =~ s/a|t|g|c|n//g;
                    my $ref_extract = substr $line, -$flank_seq_length ;
                    my $length_ref = length($line);
                    for (1..$support_reads) {
                        $line = <BP>;
                        my $subline = substr $line, $length_ref;
                        $subline =~ s/\s.+//g;
                        chomp($subline);
                        if (length($subline) > length($out5)) {
                            $out5 = $subline;
                        }
                    }
                    my $seq = $out5 . $ref_extract;
                    my $id = "$chrID\_$pos\_SR_$support_reads";
                    my $seqobj_out = Bio::PrimarySeq->new ( -seq => "$seq", -id  => "$id", -alphabet => 'dna'); 
                    $outfile->write_seq($seqobj_out);
                }
                elsif ($chain eq "-") {
                    chomp($line);
                    my $ref_extract = $line;
                    $ref_extract =~ s/a|t|g|c|n//g;
                    $ref_extract = substr $ref_extract, 0,9 ;
                    $line =~ s/A|T|G|C|N//g;
                    my $length_ref = length($line);
                    for (1..$support_reads) {
                        $line = <BP>;
                        my $subline = substr $line, 0, $length_ref;
                        $subline =~ s/^\s+//;
                        if (length($subline) > length($out3)) {
                            $out3 = $subline;
                        }
                    }
                    my $seq = $ref_extract . $out3;
                    my $id = "$chrID\_$pos\_SR_$support_reads";
                    my $seqobj_out = Bio::PrimarySeq->new ( -seq => "$seq", -id  => "$id", -alphabet => 'dna'); 
                    $outfile->write_seq($seqobj_out);
                }
                else {
                    die "line parse error, $line";
                }
            }
        }
    }
}

sub shortins_seq {
}

