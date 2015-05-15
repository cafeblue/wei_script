#! /bin/bash

get_longest_from_oases.pl transcripts.fa collapsed_transcripts.fasta
get_fasta_stats -t collapsed_transcripts.fasta > stat
awk '{print $2}' stat | sort -n |sed '1,11d' > sort
N50.pl sort 1 > N50
longest_seq=`echo \`tail -1 sort\`/100|bc`
longest_seq=`echo "($longest_seq + 1) * 100"|bc`
seq_length_distribute_v2.pl collapsed_transcripts.fasta $longest_seq 100 length_distribution
