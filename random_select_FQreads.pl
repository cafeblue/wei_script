#! /usr/bin/perl -w

#used to split a fq file or paired fq file into random two parts.

use strict;
use List::Util qw(shuffle);

sub build_index {
        my $data_file = shift;
        my $index_file = shift;
        my $offset = 0;

        while (<$data_file>) {
#				pack("CN", $i / 2**32, $i % 2**32);
                print $index_file pack("CN", $offset / 2**32, $offset % 2**32);
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
        my $d_offset1;
		my $d_offset2;

        $size = length(pack("CN", 0, 0));
        $i_offset = $size * ($line_number-1);
        seek($index_file, $i_offset, 0) or return;
        read($index_file, $entry, $size);
        ($d_offset1, $d_offset2) = unpack("CN", $entry);
        seek($data_file, $d_offset1 * 2**32 + $d_offset2, 0);
        return scalar(<$data_file>);
}

if (@ARGV < 2 ) {
	print "\n\tUsage: $0 [-p] file1 [file2]  number newfile index_id_file\n";
	print "\tFor example: $0 -p reads1.fastq reads2.fastq 5000000 Newfile index_selected.txt \n";
	print "\tFor example: $0 read1.fastq 5000000 New_Reads_file index_selected.txt\n";
	exit(0);
}

my $reads_num_selected;
my $reads_num_all;

if ($ARGV[0] eq "\-p") {
	open (FQ1, "< $ARGV[1]") or die $!;
	open (FQ2, "< $ARGV[2]") or die $!;
	open (IND, ">$ARGV[5]") or die $!;
	if (-e "$ARGV[2].idx") {
		open (INDEXFQ2, "$ARGV[2].idx") or die $!;
		open (INDEXFQ1, "$ARGV[1].idx") or die $!;
	}
	else {
		open (INDEXFQ2, "+>$ARGV[2].idx") or die $!;
		build_index(*FQ2, *INDEXFQ2);
		open (INDEXFQ1, "+>$ARGV[1].idx") or die $!;
		build_index(*FQ1, *INDEXFQ1);
	}
	open (OQ10_1, ">$ARGV[4]_sub_read1\.fastq") or die $!;
	open (OQ10_2, ">$ARGV[4]_sub_read2\.fastq") or die $!;
	$reads_num_selected = $ARGV[3];
	$reads_num_all = `wc -l $ARGV[1] | awk '{print \$1}'`;
	$reads_num_all /= 4;
	my @shuffle = shuffle 1..$reads_num_all;
	my $flag = 0;
	foreach (@shuffle) {
		if ($flag >= $reads_num_selected) {
			last;
		}
		$flag++;
		print IND $_,"\n";
		my $line = $_;
		$line *= 4;
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-3);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-2);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-1);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line);
		print OQ10_2 line_with_index(*FQ2, *INDEXFQ2, $line-3);
		print OQ10_2 line_with_index(*FQ2, *INDEXFQ2, $line-2);
		print OQ10_2 line_with_index(*FQ2, *INDEXFQ2, $line-1);
		print OQ10_2 line_with_index(*FQ2, *INDEXFQ2, $line);
	}
}

else {
	open (FQ1, "< $ARGV[0]") or die $!;
	open (IND, ">$ARGV[3]") or die $!;
	if (-e "$ARGV[0].idx") {
		open (INDEXFQ1, "$ARGV[0].idx") or die $!;
	}
	else {
		open (INDEXFQ1, "+>$ARGV[1].idx") or die $!;
		build_index(*FQ1, *INDEXFQ1);
	}
	open (OQ10_1, ">$ARGV[2]_sub\.fastq") or die $!;
	$reads_num_selected = $ARGV[1];
	$reads_num_all = `wc -l $ARGV[0] | awk '{print \$1}'`;
	$reads_num_all /= 4;
	my @shuffle = shuffle 1..$reads_num_all;
	my $flag = 0;
	foreach (@shuffle) {
		if ($flag >= $reads_num_selected) {
			last;
		}
		$flag++;
		print IND $_,"\n";
		my $line = $_;
		$line *= 4;
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-3);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-2);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line-1);
		print OQ10_1 line_with_index(*FQ1, *INDEXFQ1, $line);
	}
}
