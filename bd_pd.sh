#! /bin/bash

if [[ $1 == "" ]];
then 
    echo "";
    echo "    Usage: $0 bamfile reference_fasta_file";
    echo "";
    echo -e "    !!! \e[91m\e[5mWarning:\e[0m Please index each .bam file and name the .bai file as filename.bam.bai, not filename.bai !!!"
    echo "";
    exit 0;
fi

bam=$1;

bam2cfg.pl $bam > ${bam/.bam/.bdcfg};
awk '{print $3"\t"$9"\t"$3}' ${bam/.bam/.bdcfg} | sed 's/map://g;s/mean://' > ${bam/.bam/.pdcfg};
breakdancer-max ${bam/.bam/.bdcfg} > ${bam/.bam/.ctx};
pindel -f $2 -i ${bam/.bam/.pdcfg} -c ALL -b ${bam/.bam/.ctx} -o ${bam/.bam/_pindel} 
