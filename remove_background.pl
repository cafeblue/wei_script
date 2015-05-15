#! /usr/bin/perl -w

use strict;

if (@ARGV < 1) {
	die "\n\tUsage: $0 ssaha2_file1 ssaha2_file2 fq_file1 fq_file2 output_fq1 output_fq2\n\tor    $0 ssaha2_file1 fq_file1 output_fq1\n";
}

elsif (@ARGV < 4) {
	my %list;
	my @fq = ();
	my $flag = 0;
	my $id = 0;
	open (SSA1, "$ARGV[0]") or die $!;
	while (<SSA1>) {
		if (/^Matches For Query (\d+) /) {
			$id = $1;
			$flag++;
		}
		elsif (/^$/) {
			if ($flag == 1) {
				$list{$id} = 1;
			}
			$flag = 0;
		}
		elsif (/^ALIGNMENT/) {
			$flag++;
		}
	}

	my $selected = scalar keys %list;
	print "$selected of $id Selected! about ", sprintf ('%5.2f',  $selected/$id*100), "\t $ARGV[1]\n";

	open (FQ1, "$ARGV[1]") or die $!;
	open (OQ1, ">$ARGV[2]") or die $!;
	while (<FQ1>) {
		my $line = int(($.-1)/4);
		if (exists $list{$line}) {
			print OQ1 $_;
		}
	}
}

else {
	my %list;
	my @fq = ();
	my $flag = 0;
	my $id = 0;
	open (SSA1, "$ARGV[0]") or die $!;
	while (<SSA1>) {
		if (/^Matches For Query (\d+) /) {
			$id = $1;
			$flag++;
		}
		elsif (/^$/) {
			if ($flag == 1) {
				$list{$id} = 1;
			}
			$flag = 0;
		}
		elsif (/^ALIGNMENT/) {
			$flag++;
		}
	}
	close(SSA1);

	my $selected = scalar keys %list;
	print "$selected of $id Seleted! \t $ARGV[2]\n";

	open (SSA2, "$ARGV[1]") or die $!;
	while (<SSA2>) {
		if (/^Matches For Query (\d+) /) {
			$id = $1;
		}
		elsif (/^ALIGNMENT/) {
			if (exists $list{$id}) {
				delete $list{$id};
			}
		}
	}

	$selected = scalar keys %list;
	print "$selected of $id Selected! about ", sprintf ('%5.2f',  $selected/$id*100), "\t $ARGV[2] $ARGV[3]\n";

	open (FQ1, "$ARGV[2]") or die $!;
	open (OQ1, ">$ARGV[4]") or die $!;
	while (<FQ1>) {
		my $line = int(($.-1)/4);
		if (exists $list{$line}) {
			print OQ1 $_;
		}
	}
	open (FQ2, "$ARGV[3]") or die $!;
	open (OQ2, ">$ARGV[5]") or die $!;
	while (<FQ2>) {
		my $line = int(($.-1)/4);
		if (exists $list{$line}) {
			print OQ2 $_;
		}
	}
}

