#! /usr/bin/perl -w

# Writen by Wei Wang on Dec. 26 2010
# The last job!

use strict;
use DBI();

if (@ARGV < 1) {
	print "\n\tUsage: $0 command parameters";
	print "\n\tExample: $0 update directory configure_file";
	print "\n\tExample: $0 search \"string\"";
	print "\n\tPlease use special command to see the detailed parameters\n";
	exit (0);
}

elsif (@ARGV <= 1) {
	if ($ARGV[0] eq "update") {
		print "\n\tUsage: $0 update directory configure_file";
		print "\n\tExample: $0 update /home/gene/bioinfo/454/ config.txt";
		print "\n\tExample: $0 update . config.txt";
		print "\n\n\tconfig.txt file should be like below: ";
		print "\n\n\t\#date platform species type filename insert_size Paired_End_or_Mate_Paired Project_name Customer_name";
		print "\n\t20101226\t454\tNannochloropsis_oz1\tgdna\t1.TCA.fna\t0\tN\tAlgae\tBEGC";
		print "\n\t20101226\t454\tNannochloropsis_oz1\tgdna\tFXOS07M02.sff\t20Kbp\tP\tAlgae\tBEGC";
		print "\n\t20101226\tSolexa\tPseudococum_sp.\tcdna\ts_1_1_sequence.txt\t250bp\tP\tAlgae\tBEGC";
		print "\n\t20101226\tSolexa\tPseudococum_sp.\tmrna\ts_2_1_sequence.txt\t150bp\tP\tAlgae\tBEGC";
		print "\n\t20101226\tSolexa\tUnknown\tmicrorna\ts_3_1_sequence.txt\t3Kbp\tM\tAlgae\tBEGC";
		print "\n\t20101226\tSolexa\tSchistosoma_japanicum\tgdna\ts_4_1_sequence.txt\t4Kbp\tM\thorizon\tYMTD";
		print "\n\t20101226\tSolexa\tmetagenome_oral_16S\tmeta_gdna\ts_5_1_sequence.txt\t5Kbp\tM\thorizon\tAutolab";
		print "\n\t20101226\tSolexa\tmetagenome_ruman_16S\tmeta_cdna\ts_6_1_sequence.txt\t5Kbp\tM\t\tOUC";
		print "\n\t20101226\tSolexa\tmetagenome_earth_16S\tmeta_mrna\ts_7_1_sequence.txt\t5Kbp\tM\tAlgae\tIM";
		print "\n\t20101226\tSolexa\tSchistosoma_mansonia\tmeta_16S\ts_8_1_sequence.txt\t5Kbp\tM\tAlgae\tBIG\n\n";
		print "\n\tCautions!!!!!!!!!!";
		print "\n\t1. data should be a 8 bit number like 20121220";
		print "\n\t2. platform should be \"454\" or \"Solexa\"";
		print "\n\t3. type should be gdna, cdna, mrna, microrna, meta_gdna, meta_cdna etc. you should use this words congruously.";
		print "\n\t4. insert size should be ended by bp, like 5Kbp or 300bp.";
		print "\n\t5. Paired End or Mate Paired should be set as N, P or M.";
		print "\n\t6. split each item with a TAB, don't insert space in each item.\n\n";
	}
	elsif ($ARGV[0] eq  "search") {
		print "\n\tUsage: $0 search string \[-data=date\] \[-platform=instrument\] \[-insertsize=length\] \[-type=type\]";
		print "\n\tExample: $0 search BIG";
		print "\n\t\t $0 search megatenome_oral_16S";
		print "\n\t\t $0 search -platform=Solexa";
		print "\n\t\t $0 search Unknown -data>20100112";
		print "\n\t\t $0 search Pseudococum_sp. -data<20100112 -platform=Solexa";
		print "\n\t\t $0 search metagenome_earth_16S -data<20100909 -platform=454 -insertsize=300bp -type=meta_gdna\n\n";
	}
	else {
		print "\n\tAre you kidding me?!";
		print "\n\tPlease see the manual with running this script in no parameter.\n";
	}  
	exit(0);
}

sub update{
	use vars qw($dbh);
	my $location;
	my $infile;
	($location, $infile) = @_;
	if ($location eq "\.") {
		$location = `pwd`;
		chomp($location);
		$location .= "\/";
	}
	system("cat $infile");
	print "\nLocation of the files is $location\n\n";
	print "\nPlease make sure the information is CORRECT!!! (Y/N):";
	my $confirm = <STDIN>;
	chomp($confirm);
	if ($confirm ne "Y" and $confirm ne "y") {
		exit(0);
	}
	open (INF, $infile) or die $!;
	while (<INF>) {
		if (not /^\#/){
			chomp;
			my $string = $_;
			$string .= "\t$location\"";
			$string =~ s/\t/\"\, \"/g;
			$string = "\"".$string;
			my $insert = "insert into data_list VALUES ($string)";
			$dbh->do($insert) or die $dbh->errstr;
		}
	}
	print "\n\nUpdate the database successfully!\n";
}

sub search{
	use vars qw($dbh);
	my $cmd_tail = "";
	my $cmd_head = "";
	my $cmd = "select \* from data_list ";
	foreach (@_) {
		if (/^\-date/) {
			my $data = $_;
			$data =~ s/\-date//;
			if ($data =~ /\=/) {
				$data =~ s/\=/\=\ \'/;
			}
			else {
				$data =~ s/\>/\>\=\ \'/;
				$data =~ s/\</\<\=\ \'/;
			}
			if ($cmd_tail eq "") {
				$cmd_tail = " \`date\` $data\' ";
			}
			else {
				$cmd_tail .= " and \`date\` $data\' ";
			}
		}
		elsif (/^\-platform\=/) {
			my $platform = $_;
			$platform =~ s/\-platform\=//;
			if ($cmd_tail eq "") {
				$cmd_tail = " \`platform\` = \'$platform\' ";
			}
			else {
				$cmd_tail .= " and \`platform\` = \'$platform\' ";
			}
		}
		elsif (/^\-insertsize\=/) {
			my $insertsize = $_;
			$insertsize =~ s/\-insertsize\=//;
			if ($cmd_tail eq "") {
				$cmd_tail = " \`insert_size\` = \'$insertsize\' ";
			}
			else {
				$cmd_tail .= " and \`insert_size\` = \'$insertsize\' ";
			}
		}
		elsif (/^\-type/) {
			my $type = $_;
			$type =~ s/\-type\=//;
			if ($cmd_tail eq "") {
				$cmd_tail = " \`type\` = \'$type\' ";
			}
			else {
				$cmd_tail = " and \`type\` = \'$type\' ";
			}
		}
		else {
			$cmd_head = "WHERE `species\` LIKE \'\%$_\%\' OR \`Project_name\` LIKE \'\%$_\%\' OR \`Customer_name\` LIKE  \'\%$_\%\'";
		}
	}
	if ($cmd_tail eq "") {
		$cmd .= $cmd_head."\;";
	}
	elsif ($cmd_head eq "") {
		$cmd .= "WHERE $cmd_tail"."\;";
	}
	else {
		$cmd .= $cmd_head." AND ".$cmd_tail."\;";
	}
	my @result = @{$dbh->selectall_arrayref("$cmd", { Slice => {} })};
	print "#date\tplatform\tspecies\ttype\tinsert_size\tP\/M\tProj_name\tCustomer_name\tLocation\n";
	foreach my $gid  (@result) {
		print $gid->{date},"\t",$gid->{platform},"\t",$gid->{species},"\t",$gid->{type},"\t",$gid->{insert_size},"\t",$gid->{Paired_End_or_Mate_Paired},"\t",$gid->{Project_name},"\t",$gid->{Customer_name},"\t",$gid->{location},$gid->{filename},"\n";
	}
}

$dbh = DBI->connect("DBI:mysql:database=DataManager;host=124.16.151.190","cafeblue", "bacdavid",{'RaiseError' => 1});

if ($ARGV[0] eq "update") {
	update($ARGV[1], $ARGV[2]);
}

elsif ($ARGV[0] eq "search") {
	my @parameters = @ARGV;
	shift @parameters;
	search(@parameters);
}

else {
	print "\n\tAre you kidding me?!";
	print "\n\tPlease see the manual in no parameter.\n";
}
	





