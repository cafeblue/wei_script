#!/usr/bin/perl -w

use strict;
use warnings;
use File::Find;

if (@ARGV<3 || @ARGV>3) {
	die"perl ex_dbSNP_4.4.pl <SNP file> <dbSNP file> <Output file annoed by dbSNP>\n";
}
unless (-e $ARGV[1]){
	die"The dbSNP file is not existent!\n";
}
unless (-e $ARGV[0]){
	die"The sample directory is not existent!\n";
}



my $file_path="";
my $file_path2="";
my $file_path3="";
my $file_path4="";
my $file; 
my @files;
my @ordered_files;
my @result_files;
my @exdbsnp_files;
	

if ($ARGV[0]=~ /\./) {
	$file_path=$ARGV[0];
	$file_path2=$ARGV[2];
	$file_path3=$ARGV[3];
	push (@ordered_files,$file_path);
	push (@result_files,$file_path2);
	push (@exdbsnp_files,$file_path3);
}
else {
	mkdir ($ARGV[2]);
	mkdir ($ARGV[3]);
#	mkdir ($ARGV[2],0755);
#	mkdir ($ARGV[3],0755);
	opendir (DIR,$ARGV[0]); 
	@files = readdir DIR; 
	foreach $file(@files) { 
		if ( $file =~ /txt/) { 
			$file_path="$ARGV[0]/$file";
			$file_path2="$ARGV[2]/$file";
			$file_path3="$ARGV[3]/$file";
			push (@ordered_files,$file_path);
			push (@result_files,$file_path2);
			push (@exdbsnp_files,$file_path3);
		} 
	}
}

my %hash1=('A'=>'T','T'=>'A','C'=>'G','G'=>'C','-'=>'-','N'=>'N');
my %hash_RS;
my @line;
my $new_line;
my $asc=0;
my $a;
my $n=0;
my $n1=0;
my $n2=0;
my @id;
my @line9;
my $b;

$file_path4=$ARGV[1];
open (DBSNP,"<$file_path4");
while (<DBSNP>) {
	chomp;
	@line=split(/\s/,$_);
	$line[1]=~ s/^(chr)?//;
	unless ($line[9]=~ /[[:alpha:]][[:alpha:]]/ || $line[7]=~ /[[:alpha:]][[:alpha:]]/ || $line[9]=~ /[0-9]/ || $line[9]=~ /\(/) {

		if ($line[6]=~ /-/) {
			$b=$hash1{$line[7]};
			$line[9]=~ s/($b\/)//g;
			@line9=split(/\//,$line[9]);
			foreach $a(@line9) {
				$n=ord($hash1{$a});
				$n2=ord($line[7]);
				$asc=$asc + $n + $n2;
				$new_line="$line[1]$line[3]$asc";
				$hash_RS{$new_line}=$line[4];
				$asc=0;
			}
		}
		else {
			$line[9]=~ s/$line[7]\///;
			@line9=split(/\//,$line[9]);
			foreach $a(@line9) {
				$n=ord($a);
				$n2=ord($line[7]);
				$asc=$asc + $n + $n2;
				$new_line="$line[1]$line[3]$asc";
				$hash_RS{$new_line}=$line[4];
				$asc=0;
			}
		}
	}
}
close DBSNP;
#print "\n\n=================================================================\n ";
my $i=0;
my $path;
my @line3;
my $print_line;
my $sign1=0;
my $sign2=0;
my %hash2;
my @print_array;
my @print_array2;



foreach  $path(@ordered_files) {
	open (SAMPLE,"<$path");
	open (EXTRACT,">$result_files[$i]");



	while (<SAMPLE>) {
		
#		if ($_=~ /\#/, || /READ_DEPTH/,$_) {
#			next;
#		}
		chomp;
		$print_line=$_;
		
		@line=split(/\t/,$_);
		$line[0]=~ s/^(chr)?//;
		$line[3]=~ s/\,//g;
			@line3=split(//,$line[3]);
			foreach  $a(@line3) {
				$n=ord($a);
				$n1=ord($line[2]);
				$asc=$n + $n1;
				$new_line="$line[0]$line[1]$asc";
				$hash2{$new_line}="chr$line[0]\t$line[1]\t$line[2]\t$a\t$line[4]\t$line[5]\t$line[6]\t$line[7]";
				if ($hash_RS{$new_line} && @line==8) {
					print EXTRACT "$hash2{$new_line}\tdbsnp\t$hash_RS{$new_line}\n";
#					print "$new_line\n";
				}
				else{
					print EXTRACT "$hash2{$new_line}\n";
#					push(@print_array2,$hash2{$new_line});
##					print "$new_line***\n";
				}
#				print "------------------\n";
				$asc=0;
			}
	}

#	my %tmp_hash= map {$_=>1}@print_array;
#	@print_array=keys %tmp_hash;
#	my %tmp_hash2= map {$_=>1}@print_array2;
#	@print_array2=keys %tmp_hash2;
#	print EXTRACT "@print_array";
#	print AIMSNP "@print_array2";
	close (EXTRACT);


	$i++;
	close SAMPLE;
}
