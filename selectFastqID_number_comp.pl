#! /usr/bin/perl -w

# this script will extract the IDs (in number) in a list file from a fastq file.
# Writen by Wang Wei Sep. 15, 2010 

#inputfile format:
#3 
#4
#6
#9
#18
#23

# means the third forth sixth ... sequence.


use strict;

sub build_index {
        my $data_file = shift;
        my $index_file = shift;
        my $offset = 0;

        while (<$data_file>) {
                print $index_file pack("N", $offset);
                $offset = tell($data_file);
        }
}

sub line_with_index {
        my $data_file = shift;
        my $index_file = shift;
        my $line_number = shift;

        my $size;
        my $i_offset;
        my $entry;
        my $d_offset;

        $size = length(pack("N", 0));
        $i_offset = $size * ($line_number-1);
        seek($index_file, $i_offset, 0) or return;
        read($index_file, $entry, $size);
        $d_offset = unpack("N", $entry);
        seek($data_file, $d_offset, 0);
        return scalar(<$data_file>);
}

if (@ARGV < 3) {
    print "\n\tUsage: $0 reads_list fastq_file outfile";
    print "\n\tExample: $0 list.txt s_7_1_sequences.txt now_reads.fq\n\n";
    exit(0);
}

open (FQ, "< $ARGV[1]") or die $!;
if (-e "$ARGV[1].idx"){
	open (INDEX, "$ARGV[1].idx") or die $!;
}
else {
	open (INDEX, "+>$ARGV[1].idx") or die $!;
	build_index(*FQ, *INDEX);
}

open (LIST, "$ARGV[0]") or die $!;
open (OUP, ">$ARGV[2]") or die $!;
my $total += tr/\n/\n/ while sysread($ARGV[1], $_, 2 ** 16);
$total \= 4;
my $line = 1;

while (<LIST>) {
	chomp;
	while ($line < $_) {
		for (my $i = 0; $i<4; $i++) {
			my $line_number = $line * 4 + $i - 3;
			print OUP line_with_index(*FQ, *INDEX, $line_number);
		}
		$line++;
	}
	if ($line = $_) {
		$line++;
	}
}

while ($line < $total) {
    for (my $i = 0; $i<4; $i++) {
        my $line_number = $line * 4 + $i - 3;
        print OUP line_with_index(*FQ, *INDEX, $line_number);
    }
    $line++;
}
