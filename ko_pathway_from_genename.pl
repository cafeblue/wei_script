#! /usr/bin/perl 

use strict;

my $usage = <<"USAGE";

    Usage: $0 list_file Species out_file
    Example: $0 gene_name.txt GGA ko_pathway.txt

USAGE

if (@ARGV < 3) {
    die $usage;
}

open (GID, "$ARGV[0]") or die $!;

open (OUF, ">$ARGV[2]") or die $!;
my %hash;
while (<GID>) {
    chomp;
    s/\"//g;
    $hash{$_} = "";
}
open (KO, "/share/data/database/Kegg/ko") or die $!;
my $flag = 0;
my $pathway;
my $genename;

while (<KO>) {
    if (/^ENTRY/ && $flag == 0) {
        $flag++;
    }
    elsif (/^PATHWAY     (ko\d{5})/ && $flag == 1) {
        $flag++;
        $pathway = $1;
    }
    elsif (/^            (ko\d{5})/ && $flag == 2) {
        $pathway .= "; $1";
    }
    elsif (/^GENES/ && $flag == 2) {
        $flag++;
        if (/$ARGV[1]: (.+)$/) {
            my $names = $1;
            $names =~ s/\(.+?\)//g;
            chomp($names);
            my @names = split(/\s/, $names);
            foreach (@names) {
                if (exists $hash{$_}) {
                    if ($hash{$_} eq "") {
                        $hash{$_} = $pathway;
                    }
                    else {
                        $hash{$_} .= "; $pathway";
                    }
                }
            }
        }
        my $temp_line = <KO>;
        while ($temp_line =~ /^                 (.+)$/) {
            my $names = $1;
            $names =~ s/\(.+?\)//g;
            chomp($names);
            my @names = split(/\s/, $names);
            foreach (@names) {
                if (exists $hash{$_}) {
                    if ($hash{$_} eq "") {
                        $hash{$_} = $pathway;
                    }
                    else {
                        $hash{$_} .= "; $pathway";
                    }
                }
            }
            $temp_line = <KO>;
        }
    }
    elsif (/^            $ARGV[1]: (.+)$/ && $flag == 3) {
        my $names = $1;
        $names =~ s/\(\w+?\)//g;
        chomp($names);
        my @names = split(/\s/, $names);
        foreach (@names) {
            if (exists $hash{$_}) {
                if ($hash{$_} eq "") {
                    $hash{$_} = $pathway;
                }
                else {
                    $hash{$_} .= "; $pathway";
                }
            }
        }
        my $temp_line = <KO>;
        while ($temp_line =~ /^                 (.+)$/) {
            my $names = $1;
            $names =~ s/\(\w+?\)//g;
            chomp($names);
            my @names = split(/\s/, $names);
            foreach (@names) {
                if (exists $hash{$_}) {
                    if ($hash{$_} eq "") {
                        $hash{$_} = $pathway;
                    }
                    else {
                        $hash{$_} .= "; $pathway";
                    }
                }
            }
            $temp_line = <KO>;
        }
    }
    elsif (/^\/\/\//) {
        $flag = 0;
    }
}

foreach (keys %hash) {
    print OUF "$_\t$hash{$_}\n";
}
