#! /share/data/software/ActivePerl-5.12/bin/perl
use strict;
use DBI();

open (OUF, ">/tmp/kegg.txt") or die $!;
my %hash;

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
        my $spe;
        if (/([A-Z]{3}): (.+)$/) {
            $spe = $1;
            my $names = $2;
            $names =~ s/\)//g;
            $names =~ s/\(/ /g;
            chomp($names);
            my @names = split(/\s+/, $names);
            foreach (@names) {
                if (exists $hash{$_}{$spe}) {
                    $hash{$_}{$spe} .= "; $pathway";
                }
                else {
                    $hash{$_}{$spe} .= "$pathway";
                }
            }
        }
        my $temp_line = <KO>;
        while ($temp_line =~ /^                 (.+)$/) {
            my $names = $1;
            $names =~ s/\)//g;
            $names =~ s/\(/ /g;
            chomp($names);
            my @names = split(/\s+/, $names);
            foreach (@names) {
                if (exists $hash{$_}{$spe}) {
                    $hash{$_}{$spe} .= "; $pathway";
                }
                else {
                    $hash{$_}{$spe} = "$pathway";
                }
            }
            $temp_line = <KO>;
        }
        while (1) {
            if ($temp_line =~ /^            ([A-Z]{3}): (.+)$/) {
                $spe = $1;
                my $names = $2;
                $names =~ s/\)//g;
                $names =~ s/\(/ /g;
                chomp($names);
                my @names = split(/\s+/, $names);
                foreach (@names) {
                    if (exists $hash{$_}{$spe}) {
                        $hash{$_}{$spe} .= "; $pathway";
                    }
                    else {
                        $hash{$_}{$spe} = "$pathway";
                    }
                }
            }
            $temp_line = <KO>;
            while ($temp_line =~ /^                 (.+)$/) {
                my $names = $1;
                $names =~ s/\)//g;
                $names =~ s/\(/ /g;
                chomp($names);
                my @names = split(/\s+/, $names);
                foreach (@names) {
                    if (exists $hash{$_}{$spe}) {
                        $hash{$_}{$spe} .= "; $pathway";
                    }
                    else {
                        $hash{$_}{$spe} = $pathway;
                    }
                }
                $temp_line = <KO>;
            }
            if ($temp_line =~ /^\/\/\//) {
                $flag = 0;
                last;
            }
        }
    }
}

foreach my $name (keys %hash) {
    foreach my $spe (keys %{$hash{$name}}) {
        print OUF "$spe\t$name\t";
        print OUF uniq($hash{$name}{$spe}),"\n";
    }
}

my $dbh = DBI->connect("dbi:mysql:host=192.168.5.1", "wangw" , "bacdavid") or die "Can't make database connect: $DBI::errstr\n";
my $sth = $dbh->prepare("LOAD DATA LOCAL INFILE '/tmp/kegg.txt' REPLACE INTO TABLE kegg_pathway.species_genename_pathway");
$sth->execute();
system("rm /tmp/kegg.txt");

sub uniq {
    my @tmp = split(/; /, $_[0]);
    return join("; ", keys %{{ map { $_ => 1 } @tmp }});
}
