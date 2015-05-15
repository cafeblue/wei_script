#! /bin/env perl

use strict;
use PerlIO::gzip;

open (NODE, "nodes.dmp") or die $!;
open (HEAD, "nr.head") or die $!;
open GI_P, "<:gzip", "gi_taxid_prot.dmp.gz" or die $!;
my %nodes;
my %delet;
while (<NODE>) {
    my ($tax, $f_tax) = (split(/\t\|\t/, $_))[0,1];
    $nodes{$tax} = $f_tax;
}

while (<HEAD>) {
    chomp;
    my @list = split(/gi\|/, $_);
    shift(@list);
    for (0..$#list) {
        $list[$_] =~ s/\|.+//;
    }
    if ($#list > 0) {
        for (1..$#list) {
            $delet{$list[$_]} = 0;
        }
    }
}

open (PLAT, ">viridiplantae.id") or die $!;
open (ANIM, ">metazoa.id") or die $!;
open (BACT, ">bacteria.id") or die $!;
open (ARCH, ">archaea.id") or die $!;
open (O_EU, ">other_eu.id") or die $!;
open (VIRU, ">virus_viroid.id") or die $!;
open (OTHE, ">environent_other.id") or die $!;

while (<GI_P>) {
    chomp;
    my ($gi, $tax) = (split(/\t/, $_))[0,1];
    if (not exists $nodes{$tax}) {
        print STDERR "$_\n";
        next;
    }
    elsif (exists $delet{$gi}) {
        next;
    }
    while(1) {
        if ($tax == 33090) {
            print PLAT "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 33208) {
            print ANIM "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 2157) {
            print ARCH "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 2) {
            print BACT "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 2759) {
            print O_EU "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 10239 || $tax == 12884) {
            print VIRU "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 12908 || $tax == 28384) {
            print OTHE "gi|",$gi,"\n";
            last;
        }
        elsif ($tax == 1) {
           die "Something Wrong?\n";
        }
        $tax = $nodes{$tax};
    }
}
