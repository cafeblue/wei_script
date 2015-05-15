#! /usr/bin/perl -w

# the file name should not be the total file name,
# if you specify the file parameter as "Reads",
# this stript will open the Reads.fna as the Reads
# sequences file. and open the Reads.qual as the 
# quality file.

# the second parameter used to form new files 
#named as *.fna and *.qual

# the third parameter used to form the result file.
# you'd better named it as *.xls.

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
	open (OQ10_1, ">$ARGV[3]_read1_10\.fastq") or die $!;
	open (OQ10_2, ">$ARGV[3]_read2_10\.fastq") or die $!;
	open (OQ20_1, ">$ARGV[3]_read1_20\.fastq") or die $!;
	open (OQ20_2, ">$ARGV[3]_read2_20\.fastq") or die $!;
	open (OQ30_1, ">$ARGV[3]_read1_30\.fastq") or die $!;
	open (OQ30_2, ">$ARGV[3]_read2_30\.fastq") or die $!;
	open (OQ40_1, ">$ARGV[3]_read1_40\.fastq") or die $!;
	open (OQ40_2, ">$ARGV[3]_read2_40\.fastq") or die $!;
	open (OQ50_1, ">$ARGV[3]_read1_50\.fastq") or die $!;
	open (OQ50_2, ">$ARGV[3]_read2_50\.fastq") or die $!;
	open (OQ60_1, ">$ARGV[3]_read1_60\.fastq") or die $!;
	open (OQ60_2, ">$ARGV[3]_read2_60\.fastq") or die $!;
	open (OQ70_1, ">$ARGV[3]_read1_70\.fastq") or die $!;
	open (OQ70_2, ">$ARGV[3]_read2_70\.fastq") or die $!;
	open (OQ80_1, ">$ARGV[3]_read1_80\.fastq") or die $!;
	open (OQ80_2, ">$ARGV[3]_read2_80\.fastq") or die $!;
	open (OQ90_1, ">$ARGV[3]_read1_90\.fastq") or die $!;
	open (OQ90_2, ">$ARGV[3]_read2_90\.fastq") or die $!;
	open (OQ95_1, ">$ARGV[3]_read1_95\.fastq") or die $!;
	open (OQ95_2, ">$ARGV[3]_read2_95\.fastq") or die $!;
}
else {
	open (FQ1, "$ARGV[0]") or die $!;
	open (OQ10_1, ">$ARGV[1]_read1_10\.fastq") or die $!;
	open (OQ20_1, ">$ARGV[1]_read1_20\.fastq") or die $!;
	open (OQ30_1, ">$ARGV[1]_read1_30\.fastq") or die $!;
	open (OQ40_1, ">$ARGV[1]_read1_40\.fastq") or die $!;
	open (OQ50_1, ">$ARGV[1]_read1_50\.fastq") or die $!;
	open (OQ60_1, ">$ARGV[1]_read1_60\.fastq") or die $!;
	open (OQ70_1, ">$ARGV[1]_read1_70\.fastq") or die $!;
	open (OQ80_1, ">$ARGV[1]_read1_80\.fastq") or die $!;
	open (OQ90_1, ">$ARGV[1]_read1_90\.fastq") or die $!;
	open (OQ95_1, ">$ARGV[1]_read1_95\.fastq") or die $!;
}
my $flag = 0;

if ($ARGV[0] eq "\-p") {
	my $fq1 = "";
	my $fq2 = "";
	while (<FQ1>) {
		if (/^\@HWUSI-EAS/) {
			if (rand(100) <=10) {
				print OQ10_1 $fq1;
				print OQ10_2 $fq2;
			}
			if (rand(100) <=20) {
				print OQ20_1 $fq1;
				print OQ20_2 $fq2;
			}
			if (rand(100) <=30) {
				print OQ30_1 $fq1;
				print OQ30_2 $fq2;
			}
			if (rand(100) <=40) {
				print OQ40_1 $fq1;
				print OQ40_2 $fq2;
			}
			if (rand(100) <=50) {
				print OQ50_1 $fq1;
				print OQ50_2 $fq2;
			}
			if (rand(100) <=60) {
				print OQ60_1 $fq1;
				print OQ60_2 $fq2;
			}
			if (rand(100) <=70) {
				print OQ70_1 $fq1;
				print OQ70_2 $fq2;
			}
			if (rand(100) <=80) {
				print OQ80_1 $fq1;
				print OQ80_2 $fq2;
			}
			if (rand(100) <=90) {
				print OQ90_1 $fq1;
				print OQ90_2 $fq2;
			}
			if (rand(100) <=95) {
				print OQ95_1 $fq1;
				print OQ95_2 $fq2;
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
		if (/^\@HWUSI-EAS/) {
			if (rand(100) <=10) {
				print OQ10_1 $fq3;
			}
			if (rand(100) <=20) {
				print OQ20_1 $fq3;
			}
			if (rand(100) <=30) {
				print OQ30_1 $fq3;
			}
			if (rand(100) <=40) {
				print OQ40_1 $fq3;
			}
			if (rand(100) <=50) {
				print OQ50_1 $fq3;
			}
			if (rand(100) <=60) {
				print OQ60_1 $fq3;
			}
			if (rand(100) <=70) {
				print OQ70_1 $fq3;
			}
			if (rand(100) <=80) {
				print OQ80_1 $fq3;
			}
			if (rand(100) <=90) {
				print OQ90_1 $fq3;
			}
			if (rand(100) <=95) {
				print OQ95_1 $fq3;
			}
			$fq3 = $_;
		}
		else {
			$fq3 .= $_;
		}
	}
}
