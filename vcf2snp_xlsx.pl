#! /share/data/software/ActivePerl-5.12/bin/perl
###! /usr/bin/perl 
use strict;
use warnings;
use Excel::Writer::XLSX;

if (@ARGV<3 || @ARGV>3) {
	die"perl vcf2snp.pl <VCF file> <oup.xlsx> <deepth_statistics>\n";
}
unless (-e $ARGV[0]){
	die"VCF file entered is not existent!\n";
}

my @line;
my @line7;
my @dp4;
my $ref_dep=0;
my $nonref_dep=0;
my $chrome;
my @snp_count;
   $snp_count[0]=0;
   $snp_count[1]=0;
   $snp_count[2]=0;
my @indel_count;
   $indel_count[0]=0;
   $indel_count[1]=0;
   $indel_count[2]=0;
my $dep_indel;
my $dep_snp;
#my $count_test_snp=0;
#my $count_test_indel=0;


open (VCF,"<$ARGV[0]");
#open (SNP,">$ARGV[1]");
#open (INDEL,">$ARGV[2]");
my $excel = Excel::Writer::XLSX -> new ( $ARGV[1] );
my $sheet_snp = $excel->add_worksheet( "SNP" );
my $sheet_indel = $excel->add_worksheet( "INDEL" );
open (DEP,">$ARGV[2]");
print DEP "Minimal_deepth\tSNP\tINDEL\n";
#print SNP "ReferenceName\tPosition\tRefBase\tNon-ref_Base\tDepth_of_RefBase\tDepth_of_Non-ref_Base\tVarQuality\n";
#print INDEL "ReferenceName\tPosition\tRefBase\tNon-ref_Base\tDepth_of_RefBase\tDepth_of_Non-ref_Base\tVarQuality\n";

my $my_head = $excel->add_format( fg_color => 0x30, align => 'center', bold => 1);
my $my_format = $excel->add_format( fg_color => 0x2C, align => 'center');

$sheet_snp->set_column( 'A:A', 28 );
$sheet_snp->set_column( 'B:B', 9 );
$sheet_snp->set_column( 'C:C', 9 );
$sheet_snp->set_column( 'D:D', 14 );
$sheet_snp->set_column( 'E:E', 18 );
$sheet_snp->set_column( 'F:F', 23 );
$sheet_snp->set_column( 'G:G', 12 );

$sheet_indel->set_column( 'A:A', 28 );
$sheet_indel->set_column( 'B:B', 9 );
$sheet_indel->set_column( 'C:C', 48 );
$sheet_indel->set_column( 'D:D', 48 );
$sheet_indel->set_column( 'E:E', 18 );
$sheet_indel->set_column( 'F:F', 23 );
$sheet_indel->set_column( 'G:G', 12 );

$sheet_snp->write( 0, 0, "ReferenceName", $my_head );
$sheet_snp->write( 0, 1, "Position", $my_head );
$sheet_snp->write( 0, 2, "RefBase", $my_head );
$sheet_snp->write( 0, 3, "Non-ref_Base", $my_head );
$sheet_snp->write( 0, 4, "Depth_of_RefBase", $my_head );
$sheet_snp->write( 0, 5, "Depth_of_Non-ref_Base", $my_head );
$sheet_snp->write( 0, 6, "VarQuality", $my_head );

$sheet_indel->write( 0, 0, "ReferenceName", $my_head );
$sheet_indel->write( 0, 1, "Position", $my_head );
$sheet_indel->write( 0, 2, "RefBase", $my_head );
$sheet_indel->write( 0, 3, "Non-ref_Base", $my_head );
$sheet_indel->write( 0, 4, "Depth_of_RefBase", $my_head );
$sheet_indel->write( 0, 5, "Depth_of_Non-ref_Base", $my_head );
$sheet_indel->write( 0, 6, "VarQuality", $my_head );

my $lines_snp = 1;
my $lines_indel = 1;

while (<VCF>) {
	if ($_=~ /\#+/) {
#		print $_;
		next;
	}
	@line=split(/\t/,$_);
	@line7=split(/\;/,$line[7]);
	if ($line7[0]=~ /INDEL/) {
		$line7[5]=~ /DP4\=(\w+,\w+,\w+,\w+)/;
		@dp4=split(/\,/,$1);
		$dp4[0]=$dp4[0] + 0;
		$dp4[1]=$dp4[1] + 0;
		$dp4[2]=$dp4[2] + 0;
		$dp4[3]=$dp4[3] + 0;
		$ref_dep=$dp4[0] + $dp4[1];
		$nonref_dep=$dp4[2] + $dp4[3];
		$dep_indel=$dp4[0] + $dp4[1] + $dp4[2] + $dp4[3];
		if ($dep_indel >= 20 ) {
			$indel_count[2]++;
		}
		elsif ($dep_indel >= 10 ) {
			$indel_count[1]++;
		}
		elsif ($dep_indel >= 4 ) {
			$indel_count[0]++;
		}
#		elsif ($dep_indel <= 4 ) {
#			$count_test_indel++;
#		}

#		print INDEL "$line[0]\t$line[1]\t$line[3]\t$line[4]\t$ref_dep\t$nonref_dep\t$line[5]\n";

        $sheet_indel->write ( $lines_indel, 0, "$line[0]" , $my_format);
        $sheet_indel->write ( $lines_indel, 1, "$line[1]" , $my_format);
        $sheet_indel->write ( $lines_indel, 2, "$line[3]" , $my_format);
        $sheet_indel->write ( $lines_indel, 3, "$line[4]" , $my_format);
        $sheet_indel->write ( $lines_indel, 4, "$ref_dep" , $my_format);
        $sheet_indel->write ( $lines_indel, 5, "$nonref_dep" , $my_format);
        $sheet_indel->write ( $lines_indel, 6, "$line[5]" , $my_format);
        $lines_indel++;
	}
	else {
		$line7[4]=~ /DP4\=(\w+,\w+,\w+,\w+)/;
		@dp4=split(/\,/,$1);
		$dp4[0]=$dp4[0] + 0;
		$dp4[1]=$dp4[1] + 0;
		$dp4[2]=$dp4[2] + 0;
		$dp4[3]=$dp4[3] + 0;
		$ref_dep=$dp4[0] + $dp4[1];
		$nonref_dep=$dp4[2] + $dp4[3];
		$dep_snp=$dp4[0] + $dp4[1] + $dp4[2] + $dp4[3];
		if ($dep_snp >= 20 ) {
			$snp_count[2]++;
		}
		elsif ($dep_snp >= 10 ) {
			$snp_count[1]++;
		}
		elsif ($dep_snp >= 4 ) {
			$snp_count[0]++;
		}

#		elsif ($dep_snp <= 4 ) {
#			$count_test_snp++;
#		}

#		print SNP "$line[0]\t$line[1]\t$line[3]\t$line[4]\t$ref_dep\t$nonref_dep\t$line[5]\n";

        $sheet_snp->write ( $lines_snp, 0, "$line[0]" , $my_format);
        $sheet_snp->write ( $lines_snp, 1, "$line[1]" , $my_format);
        $sheet_snp->write ( $lines_snp, 2, "$line[3]" , $my_format);
        $sheet_snp->write ( $lines_snp, 3, "$line[4]" , $my_format);
        $sheet_snp->write ( $lines_snp, 4, "$ref_dep" , $my_format);
        $sheet_snp->write ( $lines_snp, 5, "$nonref_dep" , $my_format);
        $sheet_snp->write ( $lines_snp, 6, "$line[5]" , $my_format);
        $lines_snp++;
	}
	
}
$snp_count[3]=$snp_count[0] + $snp_count[1] + $snp_count[2];
$snp_count[4]=$snp_count[1] + $snp_count[2];
$indel_count[3]=$indel_count[0] + $indel_count[1] + $indel_count[2];
$indel_count[4]=$indel_count[1] + $indel_count[2];

#print "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\nREST\t$count_test_snp\t$count_test_indel\n";
#print DEP "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\nREST\t$count_test_snp\t$count_test_indel\n";
#print "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\n";
print DEP "4\t$snp_count[3]\t$indel_count[3]\n10\t$snp_count[4]\t$indel_count[4]\n20\t$snp_count[2]\t$indel_count[2]\n";

close DEP;
close VCF;
#close SNP;
#close INDEL;
