#! /bin/bash


if [[ $1 == "" || $2 == "" || $3 == "" ]];
then 
    echo "";
    echo "    Usage: $0 input.fastq.gz reads_number prefix_";
    echo "";
    exit 0;
fi

readsnum=$(($2 * 4));
echo "$readsnum reads per file...";
zcat $1 |split -d -l $readsnum - $3_spltmp
for file in $3_spltmp[0-9]* 
do 
    gzip -c $file > ${file/spltmp/}.fastq.gz;
    rm $file;
done
