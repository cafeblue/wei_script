#! /usr/bin/perl -w

use strict;

if ( $ARGV[0] eq "" || $ARGV[1] eq "") {
	print "\n\tUsage: $0 infile outfile\n\n";
	print "\n\tFor Example: $0 Reads.fasta  outfile\n";
	exit(0);
}

open (OUT, ">$ARGV[1]") || die $!;

my %reads;
my $keys;
my $seq = "";
my $poly = 0;
my $binu = 0;
my $total = 0;

my $patent1 = " ";
my $patent2 = " ";
my $flag_poly = 0;
my $flag_binu = 0;
my @longest_AT = (0, "");
my @longest_GC = (0, "");
my $total_poly_AT = 0;
my $total_poly_GC = 0;
my $total_length_AT = 0;
my $total_length_GC = 0;
my $total_length_binu = 0;
my $repeat_percent = 0;
my $total_bases = 0;

sub gc_count {
	my $seq = $_[0];
	my $tmp = $seq;
	$tmp =~ s/a//ig ;
	$tmp =~ s/t//ig ;
	return (sprintf("%.2f", 100 * length($tmp)/length($seq)));
}

open (INPUT, "$ARGV[0]") ||die $!;
print OUT "ID\tpoly\tpatent\tbinu_repeat\tpatent\tSeqs_length\trepeat\%\tGC\%\n";

while (<INPUT>) {
	$patent1 = " ";
	$patent2 = " ";
	$flag_poly = 0;
	$flag_binu = 0;
	$total_poly_GC = 0;
	$total_poly_AT = 0;
	if (! /^\>/) {
		chomp;
		$seq .= "$_";
		$total_bases += length($_);
	}
	else {
		$total++;
		if ($seq =~ /A{6,}|T{6,}|G{6,}|C{6,}/i) {
			$flag_poly = 1;
			while ($seq =~ /(A{6,})/i) {
				if (length($1) > $longest_AT[0]) {
					$longest_AT[0] = length($1);
					$longest_AT[1] = $keys;
				}
				$total_poly_AT += length($1);
				$total_length_AT += length($1);
				$patent1 .= "A"."\(".length($1)."\) ";
				my $tmp_seq = "X" x length($1);
				$seq =~ s/$1/$tmp_seq/i;
			}
			while ($seq =~ /(T{6,})/i) {
				if (length($1) > $longest_AT[0]) {
					$longest_AT[0] = length($1);
					$longest_AT[1] = $keys;
				}
				$total_poly_AT += length($1);
				$total_length_AT += length($1);
				$patent1 .= "T"."\(".length($1)."\) ";
				my $tmp_seq = "X" x length($1);
				$seq =~ s/$1/$tmp_seq/i;
			}
			while ($seq =~ /(G{6,})/i) {
				if (length($1) > $longest_GC[0]) {
					$longest_GC[0] = length($1);
					$longest_GC[1] = $keys;
				}
				$total_poly_GC += length($1);
				$total_length_GC += length($1);
				$patent1 .= "G"."\(".length($1)."\) ";
				my $tmp_seq = "X" x length($1);
				$seq =~ s/$1/$tmp_seq/i;
			}
			while ($seq =~ /(C{6,})/i) {
				if (length($1) > $longest_GC[0]) {
					$longest_GC[0] = length($1);
					$longest_GC[1] = $keys;
				}
				$total_poly_GC += length($1);
				$total_length_GC += length($1);
				$patent1 .= "C"."\(".length($1)."\) ";
				my $tmp_seq = "X" x length($1);
				$seq =~ s/$1/$tmp_seq/i;
			}
			$repeat_percent = ($total_poly_AT + $total_poly_GC)/length($seq);
			$poly++;
		}
		if ($seq =~ /(AT){5,}|(AG){5,}|(AC){5,}|(TG){5,}|(TC){5,}|(GC){5,}/i) {
			$flag_binu = 1;
			while ($seq =~ /((AT){5,})/) {
				$patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
			}
            while ($seq =~ /((TG){5,})/) {
                $patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
            }
            while ($seq =~ /((AG){5,})/) {
                $patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
            }
            while ($seq =~ /((AC){5,})/) {
                $patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
            }
            while ($seq =~ /((TC){5,})/) {
                $patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
            }
            while ($seq =~ /((GC){5,})/) {
                $patent2 .= $2 . "\(" . length($1)/2 . "\) ";
				$total_length_binu += length($1);
				my $tmp_seq = "X" x length($1);
				$seq = ~ s/$1/$tmp_seq/i;
				$repeat_percent += length($1)/length($seq);
            }
			$binu++;
		}
		if ($patent1 ne " " || $patent2 ne " ") {
			print OUT $keys,"\t",$flag_poly,"\t",$patent1,"\t",$flag_binu,"\t",$patent2,"\t",length($seq),"\t",sprintf("%.2f",$repeat_percent * 100),"\%\t";
			print OUT gc_count($seq),"\%\n";
		}
		$keys = (split(/\s/, $_))[0];
		$seq = "";
	}
}

if ($seq =~ /A{6,}|T{6,}|G{6,}|C{6,}/i) {
    $flag_poly = 1;
    while ($seq =~ /(A{6,})/i) {
		if (length($1) > $longest_AT[0]) {
			$longest_AT[0] = length($1);
			$longest_AT[1] = $keys;
		}
		$total_poly_AT += length($1);
		$total_length_AT += length($1);
		$patent1 = "A"."\(".length($1)."\) ";
		my $tmp_seq = "X" x length($1);
		$seq =~ s/$1/$tmp_seq/i;
    }                       
    while ($seq =~ /(T{6,})/i) {
		if (length($1) > $longest_AT[0]) {
			$longest_AT[0] = length($1);
			$longest_AT[1] = $keys;
		}
		$total_poly_AT = length($1);
		$total_length_AT += length($1);
		$patent1 = "A"."\(".length($1)."\) ";
		my $tmp_seq = "X" x length($1);
		$seq =~ s/$1/$tmp_seq/i;
    }                       
    while ($seq =~ /(G{6,})/i) {
		if (length($1) > $longest_AT[0]) {
			$longest_AT[0] = length($1);
			$longest_AT[1] = $keys;
		}
		$total_poly_AT += length($1);
		$total_length_GC += length($1);
		$patent1 = "A"."\(".length($1)."\) ";
		my $tmp_seq = "X" x length($1);
		$seq =~ s/$1/$tmp_seq/i;
    }                       
    while ($seq =~ /(C{6,})/i) {
		if (length($1) > $longest_AT[0]) {
			$longest_AT[0] = length($1);
			$longest_AT[1] = $keys;
		}
		$total_poly_AT = length($1);
		$total_length_GC += length($1);
		$patent1 = "A"."\(".length($1)."\) ";
		my $tmp_seq = "X" x length($1);
		$seq =~ s/$1/$tmp_seq/i;
    }
    $poly++;
}                
if ($seq =~ /(AT){5,}|(AG){5,}|(AC){5,}|(TG){5,}|(TC){5,}|(GC){5,}/i) {
    $flag_binu = 1;
    while ($seq =~ /((AT){5,})/) {
        $patent2 = $2 . "\(" . length($1)/2 . "\) ";
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }                         
    while ($seq =~ /((TG){5,})/) {
        $patent2 .= $2 . "\(" . length($1)/2 . "\) ";   
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }                         
    while ($seq =~ /((AG){5,})/) {
        $patent2 .= $2 . "\(" . length($1)/2 . "\) ";   
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }                         
    while ($seq =~ /((AC){5,})/) {
        $patent2 .= $2 . "\(" . length($1)/2 . "\) ";   
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }                         
    while ($seq =~ /((TC){5,})/) {
        $patent2 .= $2 . "\(" . length($1)/2 . "\) ";   
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }                         
    while ($seq =~ /((GC){5,})/) {
        $patent2 .= $2 . "\(" . length($1)/2 . "\) ";   
		$total_length_binu += length($1);
		my $tmp_seq = "X" x length($1);
		$seq = ~ s/$1/$tmp_seq/i;
    }
    $binu++;
}
if ($patent1 ne " " || $patent2 ne " ") {
	print OUT $keys,"\t",$flag_poly,"\t",$patent1,"\t",$flag_binu,"\t",$patent2,"\t",length($seq),"\t",sprintf("%.2f",$repeat_percent * 100),"\%\t";
	print OUT gc_count($seq),"\%\n";
}

print OUT "Total Seqs contains Poly:\t$poly\n";
print OUT "Total Seqs contains Binuclear:\t$binu\n";
print OUT "Longest A or T:\t$longest_AT[0]\t$longest_AT[1]\n";
print OUT "Longest G or C:\t$longest_GC[0]\t$longest_GC[1]\n";
print OUT "Total Poly GC: \t $total_length_GC\n";
print OUT "Total Poly AT: \t $total_length_AT\n";
print OUT "Total bases of poly repeat: \t", $total_length_AT + $total_length_GC ,"\n";
print OUT "Total bases of binucleotide repeat: \t", $total_length_binu,"\n";
print OUT "Total Sequences:\t $total\n";
print OUT "Total Bases:\t $total_bases\n";
print OUT "Total percent of poly repeat:\t",sprintf("%.2f", ($total_length_AT + $total_length_GC)/$total_bases * 100),"\%\n";
print OUT "Total Percent of Binucleotide repeat:\t", sprintf("%.2f", $total_length_binu/$total_bases * 100), "\%\n";
print OUT "Total Percent of two kinds of repeat:\t", sprintf("%.2f", ($total_length_AT + $total_length_GC + $total_length_binu)/$total_bases * 100), "\%\n";
