#!/usr/bin/perl

#------------------------------------------------------------------------------
#	Read blastn result and list position information 
#	get only the first hit from the result, and can also put the "No hits found" as a list;
#	Last modified: 2002-12-23, Wang Jianbin, wangjb@genomics.org.cn
#       Last modified: 2005-08-04, Wang Jianbin, wangjb@genomics.org.cn
#------------------------------------------------------------------------------
die "Usage:	$0	\$BlastResultFile	\$ListOutputFile	\$WantE_value	\>\[not hits found list\]\n" if(@ARGV != 3);
use strict;
my ($blast,$blastList,$evalue, %hash);
my ($QueryName,$QueryLength,$HitName,$HitLength,$Score,$Expect,$Identities1,$Identities2,$IdentitiesPercent);
my ($QueryBegin,$QueryEnd,$LibBegin,$LibEnd,$lastQueryName,$lastQueryLength,$lastHitLength,$lastHitName);

$blast = $ARGV[0];
$blastList = $ARGV[1];
$evalue = $ARGV[2];

open (BLASTN, "$blast")||die;
open (LIST, ">$blastList")||die;
print LIST "QueryName\tQueryLength\tHitName\tHitLength\tScore\tExpect\tIdentities1\tIdentities2\tIdentitiesPercent%\tQueryBegin\tQueryEnd\tLibBegin\tLibEnd\n";	

while (<BLASTN>){
	chomp;
	if (/Query= (\S+)/){	
		$QueryName = $1;
	}
	elsif (/No hits found/){
		print $QueryName,"\n";
	}
	elsif(/\((\S+)\s+letters\)/){
		$QueryLength = $1;
		$QueryLength =~ s/,//g if($QueryLength =~ /,/);
	}
	elsif (/^>(.+)/){
		$HitName = $1;
		while(<BLASTN>){
			chomp;
			if (/Length =\s+(\d+)/){
				$HitLength = $1;
				last;
			}
			else {
				$HitName .= $_;
			}
		}
		$HitName=~s/\s+/ /g;
	}	
	elsif (/Score\s*=\s*(\S+) bits.+, Expect\S* = (.+)$/){
		#----------------------
		if ($QueryBegin ne '' && $Expect <= $evalue && !exists($hash{$lastQueryName})){
			$hash{$lastQueryName} = 1;
			print LIST "$lastQueryName\t$lastQueryLength\t$lastHitName\t$lastHitLength\t$Score\t$Expect\t";
			print LIST "$Identities1\t$Identities2\t$IdentitiesPercent%\t";
			print LIST "$QueryBegin\t$QueryEnd\t$LibBegin\t$LibEnd\n";	
		}
		$lastQueryName = $QueryName;
		$lastQueryLength = $QueryLength;
		$lastHitLength = $HitLength;
		$lastHitName = $HitName;
		
		#----------------------
		$Score = $1;
		$Expect = $2;
	}
	elsif(/Identities =\s*(\d+)\/(\d+)\s*\((\d+)\%\)/){
		$Identities1 = $1;
		$Identities2 = $2;
		$IdentitiesPercent = $3;
		my $flag = 1;
		my $count = 0;
		while(<BLASTN>){
			chomp;
			if(/Query: (\d+)\s*.+\s+(\d+)$/){
				if ($flag == 1){
					$QueryBegin = $1;
				}
				$QueryEnd = $2;
			}
			elsif(/Sbjct: (\d+)\s*.+\s(\d+)$/){
				if ($flag == 1){
					$LibBegin = $1;
				}
				$LibEnd = $2;
				$flag++;
				$count = 0;
			}
			elsif(length($_) == 0){
				$count++;
			}
			if ($count == 2 || /  Database:/){
				$count = 0;
				last;
			}	
		}	
	}
}
if($Expect <= $evalue && !exists($hash{$lastQueryName})){
		print LIST "$lastQueryName\t$lastQueryLength\t$lastHitName\t$lastHitLength\t$Score\t$Expect\t";
		print LIST "$Identities1\t$Identities2\t$IdentitiesPercent%\t";
		print LIST "$QueryBegin\t$QueryEnd\t$LibBegin\t$LibEnd\n";	
}

close (LIST);
close (BLASTN);