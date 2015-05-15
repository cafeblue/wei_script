#! /usr/bin/perl -w

use strict;

my $large = 100;
my $step = 10;
my %hash;

for (my $edge = $large; $edge > 0 ; $edge -= $step) {
	$hash{$edge} = 0;
}

$hash{'0'} = 0;

my $count = 0;
while (<>) {
	chomp;
	$count++;
	for (my $edge = $large; $edge > 0 ; $edge -= $step) {
		if ($_ - $edge > 0 && $_ - $edge <= $step) {
			$hash{$edge}++;
			last;
		}
		elsif ($_ > $large) {
			$hash{$large}++;
			last;
		}
		elsif ($_ <= $step) {
			$hash{'0'}++;
			last;
		}
	}
}

my $check = 0;
foreach (sort {$a<=>$b} keys %hash) {
	$check += $hash{$_};
	if ($_ == 0) {
		print "$_ - $step\t$hash{$_}\n";
		next;
	}
	elsif ($_ == $large) {
		print "> $large\t$hash{$_}\n";
		next;
	}
	else {
		my $range = $_;
		my $end = $_ + $step;
		print "$range - $end\t$hash{$_}\n";
	}
}
print "Total:\t$count\tCheck:\t$check\n";
