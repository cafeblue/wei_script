#! /bin/env perl

use strict;
use Bio::SearchIO;

if ($#ARGV < 1) {
    die "\n\tUsage: $0 blast_result output_xls\n\n";
}

open (RES, ">$ARGV[1]") or die $!;
print RES "Query_id\tHit_ID\tE-value\tQuery_Length\tHit_length\tMatch_Length\n";

my $searchio = Bio::SearchIO->new(-format => 'blast', -file   => "$ARGV[0]");
while( my $result = $searchio->next_result ) {
    if ($result->num_hits  == 0) {
        print STDERR $result->query_name,"\n";
    }
    else {
        my $hitobj = $result->next_hit;
        print RES $result->query_name,"\t",$hitobj->name(),"\t", $hitobj->significance(),"\t",$result->query_length,"\t",$hitobj->length,"\t",$hitobj->matches('cons'), "\n";
    }
}
