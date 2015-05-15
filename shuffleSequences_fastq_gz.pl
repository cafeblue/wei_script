#!/bin/env perl

use PerlIO::gzip;

$filenameA = $ARGV[0];
$filenameB = $ARGV[1];
$filenameOut = $ARGV[2];

open $FILEA, "<:gzip", "$filenameA";
open $FILEB, "<:gzip", "$filenameB";

open $OUTFILE, ">:gzip", "$filenameOut";

while(<$FILEA>) {
	print $OUTFILE $_;
	$_ = <$FILEA>;
	print $OUTFILE $_; 
	$_ = <$FILEA>;
	print $OUTFILE $_; 
	$_ = <$FILEA>;
	print $OUTFILE $_; 

	$_ = <$FILEB>;
	print $OUTFILE $_; 
	$_ = <$FILEB>;
	print $OUTFILE $_;
	$_ = <$FILEB>;
	print $OUTFILE $_;
	$_ = <$FILEB>;
	print $OUTFILE $_;
}
