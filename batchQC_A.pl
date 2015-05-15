#!/usr/bin/perl -w

use warnings;
use strict;
use Getopt::Std;
use Getopt::Long;

###############################################################
# input options
my $usage = qq(
Usage:      batchQC.pl Parameters

Parameters: s               sequencing type: G for genome, C for cDNA. Default: T (string)
            p               type 454 or solexa to specify platform type. (string)
            t               type T for paired-end data, F for non-paired-end data. (string)
            4pe             454 paired-end reads file in fasta format. (file)
            4se             454 reads file in fasta format. NOT for paired-end reads. (file)
            sPE1            Counterpart 1 of Solexa PE reads file in fastq format. (file)
            sPE2            Counterpart 2 of Solexa PE reads file in fastq format. (file)
            sSE             Solexa reads file in fastaq format. NOT for paired-end reads. (file)
            ad              Solexa adapter sequence file in fasta format. (file)
            a               Threshold for the number of consecutive A in a read. Default: 15. (number)
            c               CPU core number. Default: 8.
            q               bsub queue. Default: gene.

Attention:  1\) DO NOT use "bsub" to submit this pipeline!
            2\) Working directory where this pipeline is invoked MUST contain one-level subdirectories named 'data' and 'tmp'!
            3\) ONLY use parameters you need!

Example:    batchQC.pl -p solexa -t T -sPE1 s_1_1_sequence.txt -sPE2 s_1_2_sequence.txt -ad adapterSequence.txt -a 15
\n);

my ($platform, $readsType, $readsPE454,$reads454, $solexaReads1,$solexaReads2,$solexaReads,$adapterSeq);
my $thresholdOfConsecutiveA = 15;
my $pwd = `pwd`;
my $pwdChomp = chomp $pwd;
my $o = $pwd.'/';
my $q = 'gene';
my $c = 8;
my $s = 'G';

&GetOptions
(
 "s:s" => \$s,
 "p:s" => \$platform,
 "t:s" => \$readsType,
 "4pe:s" => \$readsPE454,
 "4se:s" => \$reads454,
 "sPE1:s" => \$solexaReads1,
 "sPE2:s" => \$solexaReads2,
 "sSE:s" => \$solexaReads,
 "ad:s" => \$adapterSeq,
 "a:s" => \$thresholdOfConsecutiveA,
 "c:s" => \$c,
 "q:s" => \$q,
);

die($usage) if ((!defined ($platform)) || (!defined ($readsType)));
print "\n\n--------\n";
print "PROGRESS:\n";

if ($o !~ /\/$/){
	die "output directory should be ended with / \n";
}

my $bsubReturn;
my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
my $randstring = join("", @chars[ map { rand @chars } ( 1 .. 20 ) ]);
my $tmpRandDirectory = $o.'tmp/'.$randstring.'/';
my $jobLog = $tmpRandDirectory.'job.log';
my $jobErr = $tmpRandDirectory.'job.err';
my $errorLog = $tmpRandDirectory.'error.log';
system ("mkdir $tmpRandDirectory");
die "fail to create temp directory for storing intermediate files!\n" unless (-e $tmpRandDirectory);

###############################################################
# 454 reads
if ($platform eq 454){
	undef $solexaReads1;
	undef $solexaReads2;
	undef $solexaReads;
	undef $adapterSeq;
	undef $thresholdOfConsecutiveA;

	my $evalue = 1e-20;
	if ($readsType eq 'F'){
		undef $readsPE454;
		die "input error!\n" unless (-e $reads454);

		#--------file transfer--------
		print "1: file transfering\n";
		my $directoryName;
		if ($reads454 =~ /454\/(\S+).fna$/){
			$directoryName = $1;
		}elsif ($reads454 =~ /(\S+).fna$/) {
			$directoryName = $1;
		}else {
			die "input file error!\n";
		}

		$reads454 = $o.'data/454/'.$directoryName.'.fna';
		my $qualDataFile = $o.'data/454/'.$directoryName.'.qual';
		die "error: no quality file!\n" unless (-e $qualDataFile);
		my $dataDirectory = $o.'data/454/'.$directoryName.'/';
		my $dataDirectoryErrlog = $dataDirectory.'bsubError.log';
		die "directory for output not created or directory name error!\n" unless(-e $dataDirectory);

		my $fnaTmpFile = $tmpRandDirectory.$directoryName.'.fna';
		my $fnaDatalink = $dataDirectory.$directoryName.'.fna';
		my $qualDatalink = $dataDirectory.$directoryName.'.qual';
		system ("rm -f $fnaDatalink") if (-e $fnaDatalink);
		system ("rm -f $qualDatalink") if (-e $qualDatalink);
		system ("ln -fs $reads454 $tmpRandDirectory");
		system ("ln -fs $reads454 $dataDirectory");
		system ("ln -fs $qualDataFile $dataDirectory");

		#--------GC content--------
		my $gcContent = $tmpRandDirectory.'gcContent.xls';
		my $gcDistribution = $tmpRandDirectory.'gcDistribution.xls';
		my $gcDistributionProp = $tmpRandDirectory.'gcDistribution.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr gc_count.pl $fnaTmpFile $gcContent $gcDistribution $gcDistributionProp`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########sequencing type: Genome########
		if ($s eq 'T'){
		#--------megablast--------
		print "2: megablast\n";
		my $megablastResult = $tmpRandDirectory.'megablastResult';
		$bsubReturn = `bsub -q $q -n $c -o $jobLog -e $jobErr megablast -a $c -d /home/gene/bioinfo/bio_databases/nt -i $fnaTmpFile -p 0.9 -e $evalue -o $megablastResult`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastn--------
		print "3: listBlastn\n";
		my $listBlastn = $tmpRandDirectory.'listBlastnHit.xls';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr listBlastn.pl $megablastResult $listBlastn $evalue`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastnSingle--------
		print "4: listBlastnSingle\n";
		my $listBlastnSingle = $tmpRandDirectory.'listBlastnBestHit.xls';
		my $nohit = $tmpRandDirectory.'nohit.txt';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "listBlastnSingle.pl $megablastResult $listBlastnSingle $evalue > $nohit"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastn2taxonomyQCproperties--------
		print "5: listBlastn2taxonomyQCproperties\n";
		my $countGenera = $tmpRandDirectory.'countGenera.xls';
		my $countSubkingdom = $tmpRandDirectory.'countSubkingdom.xls';
		my $QCproperties = $tmpRandDirectory.'qc.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr QCbesthit2taxonomyQCproperties.pl $listBlastnSingle $nohit $countGenera $countSubkingdom $QCproperties`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------file transfer--------
		print "6: file transfering\n";
		system ("cp -f $listBlastn $dataDirectory");
		system ("cp -f $listBlastnSingle $dataDirectory");
		system ("cp -f $nohit $dataDirectory");
		system ("cp -f $countGenera $dataDirectory");
		system ("cp -f $countSubkingdom $dataDirectory");
		system ("cp -f $QCproperties $dataDirectory");
		system ("cp -f $gcContent $dataDirectory");
		system ("cp -f $gcDistribution $dataDirectory");
		system ("cp -f $gcDistributionProp $dataDirectory");
		system ("cp -f $jobLog $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		my $statusfile = $dataDirectory.'finished.checked';
		system ("touch $statusfile");
		print "COMPLETE!\n";

		########sequencing type: cDNA########
		} elsif ($s eq 'C'){

		}

	}elsif ($readsType eq 'T'){
		undef $reads454;
		die "input error!\n" unless (-e $readsPE454);

		#--------file transfer--------
		print "1: file transfering\n";
		my $directoryName;
		if ($readsPE454 =~ /454\/(\S+).fna$/){
			$directoryName = $1;
		}elsif ($readsPE454 =~ /(\S+).fna$/){
			$directoryName = $1;
		}else {
			die "input file error!\n";
		}

		my $readsPE454 = $o.'data/454/'.$directoryName.'.fna';
		my $qualDataFile = $o.'data/454/'.$directoryName.'.qual';
		die "error: no quality file!\n" unless (-e $qualDataFile);
		my $dataDirectory = $o.'data/454/'.$directoryName.'/';
		my $dataDirectoryErrlog = $dataDirectory.'bsubError.log';
		die "directory for output not created or directory name error!\n" unless(-e $dataDirectory);

		my $fnaTmpFile = $tmpRandDirectory.$directoryName.'.fna';
		my $fnaDatalink = $dataDirectory.$directoryName.'.fna';
		my $qualDatalink = $dataDirectory.$directoryName.'.qual';
		system ("rm -f $fnaDatalink") if (-e $fnaDatalink);
		system ("rm -f $qualDatalink") if (-e $qualDatalink);
		system ("ln -fs $readsPE454 $tmpRandDirectory");
		system ("ln -fs $readsPE454 $dataDirectory");
		system ("ln -fs $qualDataFile $dataDirectory");

		#--------GC content--------
		my $gcContent = $tmpRandDirectory.'gcContent.xls';
		my $gcDistribution = $tmpRandDirectory.'gcDistribution.xls';
		my $gcDistributionProp = $tmpRandDirectory.'gcDistribution.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr gc_count.pl $fnaTmpFile $gcContent $gcDistribution $gcDistributionProp`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------megablast--------
		print "2: megablast\n";
		my $megablastResult = $tmpRandDirectory.'megablastResult';
		$bsubReturn = `bsub -q $q -n $c -o $jobLog -e $jobErr megablast -a $c -d /home/gene/bioinfo/bio_databases/nt -i $fnaTmpFile -p 0.9 -e $evalue -o $megablastResult`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastn--------
		print "3: listBlastn\n";
		my $listBlastn = $tmpRandDirectory.'listBlastnHit.xls';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr listBlastn.pl $megablastResult $listBlastn $evalue`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastnSingle--------
		print "4: listBlastnSingle\n";
		my $listBlastnSingle = $tmpRandDirectory.'listBlastnBestHit.xls';
		my $nohit = $tmpRandDirectory.'nohit.txt';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "listBlastnSingle.pl $megablastResult $listBlastnSingle $evalue > $nohit"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------listBlastn2taxonomyQCproperties--------
		print "5: listBlastn2taxonomyQCproperties\n";
		my $countGenera = $tmpRandDirectory.'countGenera.xls';
		my $countSubkingdom = $tmpRandDirectory.'countSubkingdom.xls';
		my $QCproperties = $tmpRandDirectory.'qc.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr QCbesthit2taxonomyQCproperties.pl $listBlastnSingle $nohit $countGenera $countSubkingdom $QCproperties`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------file transfer--------
		print "6: file transfering\n";
		system ("cp -f $listBlastn $dataDirectory");
		system ("cp -f $listBlastnSingle $dataDirectory");
		system ("cp -f $nohit $dataDirectory");
		system ("cp -f $countGenera $dataDirectory");
		system ("cp -f $countSubkingdom $dataDirectory");
		system ("cp -f $QCproperties $dataDirectory");
		system ("cp -f $gcContent $dataDirectory");
		system ("cp -f $gcDistribution $dataDirectory");
		system ("cp -f $gcDistributionProp $dataDirectory");
		system ("cp -f $jobLog $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		my $statusfile = $dataDirectory.'finished.checked';
		system ("touch $statusfile");
		print "COMPLETE!\n";

	}else{
		die "input parameters error!\n";
	}
}elsif ($platform eq 'solexa'){

###############################################################
# solexa reads

	undef $reads454;
	undef $readsPE454;
	die "input error!\n" unless (-e $adapterSeq);

	my $evalue = 1e-5;
	if ($readsType eq 'T'){
		undef $solexaReads;
		die "input error!\n" unless ((-e $solexaReads1) && (-e $solexaReads2));

		########file transfer########
		print "1: file transfering\n";
		my $directoryName;
		if ($solexaReads1 =~ /solexa\/(\S+)_read1.fastq$/){
			$directoryName = $1;
		}elsif ($solexaReads1 =~ /(\S+)_read1.fastq$/) {
			$directoryName = $1;;
		}else {
			die "input file error!\n";
		}

		my $solexaReads1 = $o.'data/solexa/'.$directoryName.'_read1.fastq';
		my $solexaReads2 = $o.'data/solexa/'.$directoryName.'_read2.fastq';
		my $dataDirectory = $o.'data/solexa/'.$directoryName.'/';
		my $dataDirectoryErrlog = $dataDirectory.'bsubError.log';
		die "directory for output not created or directory name error!\n" unless(-e $dataDirectory);

		my $fastqTmpFile1 = $tmpRandDirectory.$directoryName.'_read1.fastq';
		my $fastqTmpFile2 = $tmpRandDirectory.$directoryName.'_read2.fastq';
		system ("ln -fs $solexaReads1 $tmpRandDirectory");
		system ("ln -fs $solexaReads2 $tmpRandDirectory");

		########batchQC_A_AT########
		my $PE_preserved1 = $tmpRandDirectory.'PE_preserved1';
		my $PE_preserved2 = $tmpRandDirectory.'PE_preserved2';
		my $PE_single = $tmpRandDirectory.'PE_single';
		my $PE_trashConsecutiveA = $tmpRandDirectory.'PE_trashConsecutiveA';
		my $PE_trashAdapter = $tmpRandDirectory.'PE_trashAdapter';

		#--------fastq2fasta--------
		print "2: fastq2fasta\n";
		my $fasta1 = $tmpRandDirectory.'fasta1';
		my $fasta2 = $tmpRandDirectory.'fasta2';
		my ($jobid1, $jobid2);
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "fq_all2std.pl fq2fa $fastqTmpFile1 > $fasta1"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid1 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "fq_all2std.pl fq2fa $fastqTmpFile2 > $fasta2"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid2 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		&bsubDog($jobid1);
		&bsubDog($jobid2);

		#--------blast--------
		print "3: blast\n";
		my $fasta1log = $fasta1.'.logfile';
		my $fasta2log = $fasta2.'.logfile';
		$bsubReturn = `bsub -n 1 -q serial -o $jobLog -e $jobErr formatdb -i $fasta1 -p F -l $fasta1log -o `;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid1 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		$bsubReturn = `bsub -n 1 -q serial -o $jobLog -e $jobErr formatdb -i $fasta2 -p F -l $fasta2log -o `;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid2 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		&bsubDog($jobid1);
		&bsubDog($jobid2);

		my $blastn1 = $tmpRandDirectory.'blastn1';
		my $blastn2 = $tmpRandDirectory.'blastn2';

		$bsubReturn = `bsub -n $c -q $q -o $jobLog -e $jobErr blastall -a $c -p blastn -d $fasta1 -i $adapterSeq -G 2 -E 1 -F F -b 1000000 -m 9 -o $blastn1`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid1 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		$bsubReturn = `bsub -n $c -q $q -o $jobLog -e $jobErr blastall -a $c -p blastn -d $fasta2 -i $adapterSeq -G 2 -E 1 -F F -b 1000000 -m 9 -o $blastn2`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			$jobid2 = $1;
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		&bsubDog($jobid1);
		&bsubDog($jobid2);

		#--------batchFilter_A_AT_solexaPE--------
		print "4: filter low-quality reads\n";
		my $statisticalReport = $tmpRandDirectory."PE"."_Statistical_Report.txt";
		$bsubReturn = `bsub -n 1 -q serial -o $jobLog -e $jobErr batchFilter_A_AT_solexaPE.pl -solexaReadsPE_NO1 $fastqTmpFile1 -solexaReadsPE_NO2 $fastqTmpFile2 -adapterSequence $adapterSeq -blastresult1 $blastn1 -blastresult2 $blastn2 -filenamePrefix PE -thresholdOfConsecutiveA $thresholdOfConsecutiveA -o $tmpRandDirectory`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}
		my $PE_preserved = $tmpRandDirectory.'PE_preserved';
		system ("cat $PE_preserved1 $PE_preserved2 $PE_single > $PE_preserved");

		########fastq2fasta########
		my $PE_preserved_fasta = $PE_preserved.'_fasta';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "fq_all2std.pl fq2fa $PE_preserved > $PE_preserved_fasta"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########GC content########
		my $gcContent = $tmpRandDirectory.'gcContent.xls';
		my $gcDistribution = $tmpRandDirectory.'gcDistribution.xls';
		my $gcDistributionProp = $tmpRandDirectory.'gcDistribution.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr gc_count.pl $PE_preserved_fasta $gcContent $gcDistribution $gcDistributionProp`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########megablast########
		print "5: megablast\n";
		my $megablastResult = $tmpRandDirectory.'megablastResult';
		$bsubReturn = `bsub -q $q -n $c -o $jobLog -e $jobErr megablast -a $c -d /home/gene/bioinfo/bio_databases/nt -i $PE_preserved_fasta -p 0.9 -e $evalue -o $megablastResult`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastn########
		print "6: listBlastn\n";
		my $listBlastn = $tmpRandDirectory.'listBlastnHit.xls';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr listBlastn.pl $megablastResult $listBlastn $evalue`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastnSingle########
		print "7: listBlastnSingle\n";
		my $listBlastnSingle = $tmpRandDirectory.'listBlastnBestHit.xls';
		my $nohit = $tmpRandDirectory.'nohit.txt';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "listBlastnSingle.pl $megablastResult $listBlastnSingle $evalue > $nohit"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastn2taxonomyQCproperties########
		print "8: listBlastn2taxonomyQCproperties\n";
		my $countGenera = $tmpRandDirectory.'countGenera.xls';
		my $countSubkingdom = $tmpRandDirectory.'countSubkingdom.xls';
		my $QCproperties = $tmpRandDirectory.'qc.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr QCbesthit2taxonomyQCproperties.pl $listBlastnSingle $nohit $countGenera $countSubkingdom $QCproperties`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########file transfer########
		print "9: file transfering\n";
		system ("cp -f $listBlastn $dataDirectory");
		system ("cp -f $listBlastnSingle $dataDirectory");
		system ("cp -f $nohit $dataDirectory");
		system ("cp -f $countGenera $dataDirectory");
		system ("cp -f $countSubkingdom $dataDirectory");
		system ("cp -f $QCproperties $dataDirectory");
		my $read1 = $dataDirectory.'read1.fastq';
		my $read2 = $dataDirectory.'read2.fastq';
		my $single = $dataDirectory.'single.fastq';
		system ("cp -f $PE_preserved1 $read1");
		system ("cp -f $PE_preserved2 $read2");
		system ("cp -f $PE_single $single");
		system ("cp -f $gcContent $dataDirectory");
		system ("cp -f $gcDistribution $dataDirectory");
		system ("cp -f $gcDistributionProp $dataDirectory");
		system ("cp -f $statisticalReport $dataDirectory");
		system ("cp -f $jobLog $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		my $statusfile = $dataDirectory.'finished.checked';
		system ("touch $statusfile");
		print "COMPLETE!\n";

	}elsif($readsType eq 'F') {
		undef $solexaReads1;
		undef $solexaReads2;
		die "input error!\n" unless (-e $solexaReads);

		########file transfer########
		print "1: file transfering\n";
		my $directoryName;
		if ($solexaReads =~ /solexa\/(\S+).fastq$/){
			$directoryName = $1;
		}elsif ($solexaReads =~ /(\S+).fastq$/) {
			$directoryName = $1;
		}else{
			die "input file error!\n";
		}

		my $solexaReads = $o.'data/solexa/'.$directoryName.'.fastq';
		my $dataDirectory = $o.'data/solexa/'.$directoryName.'/';
		my $dataDirectoryErrlog = $dataDirectory.'bsubError.log';
		die "directory for output not created or directory name error!\n" unless(-e $dataDirectory);

		my $fastqTmpFile = $tmpRandDirectory.$directoryName.'.fastq';
		system ("ln -fs $solexaReads $tmpRandDirectory");

		########batchQC_A_AT_nonPE########
		my $nonPE_single = $tmpRandDirectory.'nonPE_single';
		my $nonPE_trashConsecutiveA = $tmpRandDirectory.'nonPE_trashConsecutiveA';
		my $nonPE_trashAdapter = $tmpRandDirectory.'nonPE_trashAdapter';

		#--------fastq2fasta--------
		print "2: fastq2fasta\n";
		my $fasta = $tmpRandDirectory.'fasta';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "fq_all2std.pl fq2fa $fastqTmpFile > $fasta"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------blast--------
		print "3: blast\n";
		my $fastalog = $fasta.'.logfile';
		$bsubReturn = `bsub -n 1 -q serial -o $jobLog -e $jobErr formatdb -i $fasta -p F -l $fastalog -o `;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		my $blastn = $tmpRandDirectory.'blastn';
		$bsubReturn = `bsub -n $c -q $q -o $jobLog -e $jobErr blastall -a $c -p blastn -d $fasta -i $adapterSeq -G 2 -E 1 -F F -b 1000000 -m 9 -o $blastn`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		#--------batchFilter_A_AT_solexa--------
		print "4: filter low-quality reads\n";
		my $statisticalReport = $tmpRandDirectory."nonPE"."_Statistical_Report.txt";
		$bsubReturn = `bsub -n 1 -q serial -o $jobLog -e $jobErr batchFilter_A_AT_solexaNonPE.pl -solexaReads $fastqTmpFile -adapterSequence $adapterSeq -blastresult $blastn -filenamePrefix nonPE -thresholdOfConsecutiveA $thresholdOfConsecutiveA -o $tmpRandDirectory`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########fastq2fasta########
		my $nonPE_single_fasta = $nonPE_single.'_fasta';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "fq_all2std.pl fq2fa $nonPE_single > $nonPE_single_fasta"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########GC content########
		my $gcContent = $tmpRandDirectory.'gcContent.xls';
		my $gcDistribution = $tmpRandDirectory.'gcDistribution.xls';
		my $gcDistributionProp = $tmpRandDirectory.'gcDistribution.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr gc_count.pl $nonPE_single_fasta $gcContent $gcDistribution $gcDistributionProp`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########megablast########
		print "5: megablast\n";
		my $megablastResult = $tmpRandDirectory.'megablastResult';
		$bsubReturn = `bsub -q $q -n $c -o $jobLog -e $jobErr megablast -a $c -d /home/gene/bioinfo/bio_databases/nt -i $nonPE_single_fasta -p 0.9 -e $evalue -o $megablastResult`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastn########
		print "6: listBlastn\n";
		my $listBlastn = $tmpRandDirectory.'listBlastnHit.xls';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr listBlastn.pl $megablastResult $listBlastn $evalue`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastnSingle########
		print "7: listBlastnSingle\n";
		my $listBlastnSingle = $tmpRandDirectory.'listBlastnBestHit.xls';
		my $nohit = $tmpRandDirectory.'nohit.txt';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr "listBlastnSingle.pl $megablastResult $listBlastnSingle $evalue > $nohit"`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########listBlastn2taxonomyQCproperties########
		print "8: listBlastn2taxonomyQCproperties\n";
		my $countGenera = $tmpRandDirectory.'countGenera.xls';
		my $countSubkingdom = $tmpRandDirectory.'countSubkingdom.xls';
		my $QCproperties = $tmpRandDirectory.'qc.properties';
		$bsubReturn = `bsub -q serial -n 1 -o $jobLog -e $jobErr QCbesthit2taxonomyQCproperties.pl $listBlastnSingle $nohit $countGenera $countSubkingdom $QCproperties`;
		if ($bsubReturn =~ /^Job\s<(\d+)>\sis\ssubmitted/){
			&bsubDog($1);
		}else{
			open BSUBERR, ">$dataDirectoryErrlog" or die "$!";
			print BSUBERR "bsub error!\n";
			die "bsub error: $!";
		}

		########file transfer########
		print "9: file transfering\n";
		system ("cp -f $listBlastn $dataDirectory");
		system ("cp -f $listBlastnSingle $dataDirectory");
		system ("cp -f $nohit $dataDirectory");
		system ("cp -f $countGenera $dataDirectory");
		system ("cp -f $countSubkingdom $dataDirectory");
		system ("cp -f $QCproperties $dataDirectory");
		my $single = $dataDirectory.'single.fastq';
		system ("cp -f $nonPE_single $single");
		system ("cp -f $statisticalReport $dataDirectory");
		system ("cp -f $gcContent $dataDirectory");
		system ("cp -f $gcDistribution $dataDirectory");
		system ("cp -f $gcDistributionProp $dataDirectory");
		system ("cp -f $jobLog $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		system ("cp -f $jobErr $dataDirectory");
		my $statusfile = $dataDirectory.'finished.checked';
		system ("touch $statusfile");
		print "COMPLETE!\n";

	}else{
		die "input parameters error!\n";
	}
}else{
	die "input parameters error!\n";
}

###############################################################
# watch dog for bsub
sub bsubDog {
	if (!defined(@_)){
		die "bsub error!:$!\n";
	}
	my $watchdog;
	my @tmp;
	while (1) {
		@tmp = `bjobs`;
		foreach (@tmp) {
			chomp;
			if (/^(@_)/) {
				$watchdog = $1;
			}
		}
		if ( defined($watchdog) ) {
			undef $watchdog;
			sleep 30;
			next;
		}else {
			return 1;
			last;
		}
	}
}
