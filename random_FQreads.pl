#! /usr/bin/perl -w

#used to split a fq file or paired fq file into random two parts.

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

if (@ARGV < 2 ) {
	print "\n\tUsage: $0 [-p] file1 [file2]  newfile \n";
	print "\tFor example: $0 -p reads1.fastq reads2.fastq Newfile \n";
	print "\tFor example: $0 read1.fastq New_Reads_file\n";
	exit(0);
}

if ($ARGV[0] eq "\-p") {
	open (FQ1, "$ARGV[1]") or die $!;
	open (FQ2, "< $ARGV[2]") or die $!;
	if (-e "$ARGV[2].idx") {
		open (INDEXFQ2, "$ARGV[2].idx") or die $!;
	}
	else {
		open (INDEXFQ2, "+>$ARGV[2].idx") or die $!;
		build_index(*FQ2, *INDEXFQ2);
	}
	open (OQ10_1, ">$ARGV[3]_1_read1\.fastq") or die $!;
	open (OQ10_2, ">$ARGV[3]_1_read2\.fastq") or die $!;
	open (OQ20_1, ">$ARGV[3]_2_read1\.fastq") or die $!;
	open (OQ20_2, ">$ARGV[3]_2_read2\.fastq") or die $!;
}
else {
	open (FQ1, "$ARGV[0]") or die $!;
	open (OQ10_1, ">$ARGV[1]_1\.fastq") or die $!;
	open (OQ20_1, ">$ARGV[1]_2\.fastq") or die $!;
}
my $flag = 0;

if ($ARGV[0] eq "\-p") {
	my $fq1 = "";
	my $fq2 = "";
	while (<FQ1>) {
		if (/^\@HWI-EAS/) {
			if (rand(100) <=50) {
				print OQ10_1 $fq1;
				print OQ10_2 $fq2;
			}
			else {
				print OQ20_1 $fq1;
				print OQ20_2 $fq2;
			}
			$fq1 = $_;
			$fq2 = line_with_index(*FQ2, *INDEXFQ2, $.);
		}
		else {
			$fq1 .= $_;
			$fq2 .= line_with_index(*FQ2, *INDEXFQ2, $.);
		}
	}
}

else {
	my $fq3 = "";
	while (<FQ1>) {
		if (/^\@HWI-EAS737/) {
			if (rand(100) <=50) {
				print OQ10_1 $fq3;
			}
			else {
				print OQ20_1 $fq3;
			}
			$fq3 = $_;
		}
		else {
			$fq3 .= $_;
		}
	}
}
