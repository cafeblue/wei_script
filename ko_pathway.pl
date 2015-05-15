#! /usr/bin/perl -w

my %ko_path;
open (KO, "/share/data/database/Kegg/ko") or die $!;

while (<KO>) {
    if (/     (ko\d{5})  (.+)/) {
        my $ko = $1;
        my $pa = $2;
        if (not exists $ko_path{$ko}) {
            $ko_path{$ko} = $pa;
        }
    }
}

foreach my $keys (keys %ko_path) {
    print $keys,"\t",$ko_path{$keys},"\n";
}
