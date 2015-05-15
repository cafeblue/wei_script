#!/bin/env perl

use PerlIO::gzip;
use PerlIO::via::Bzip2;

$filenameA = $ARGV[0];
$filenameB = $ARGV[1];
$filenameOut = $ARGV[2];

open $FILEA, "<:via(Bzip2)", "$filenameA";
open $FILEB, "<:via(Bzip2)", "$filenameB";

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
